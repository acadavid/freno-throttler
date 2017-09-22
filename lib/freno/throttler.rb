require "freno/throttler/version"
require "freno/throttler/instrumenter"
require "freno/throttler/mapper"
require "freno/throttler/errors"

module Freno

  # Freno::Throttler is the class responsible for throttling writes to a cluster
  # or a set of clusters. Throttling means to slow down the pace at which write
  # operations occur by checking with freno whether all the clusters affected by
  # the operation are in good health before allowing it. If any of the clusters
  # is not in good health, the throttler will wait some time and repeat the
  # process.
  #
  # Examples:
  #
  # Let's use the following throttler, which uses Mapper::Identity implicitly.
  # (see #initialze docs)
  #
  # ```
  # throttler = Throttler.new(client: freno_client, app: :my_app)
  # data.find_in_batches do |batch|
  #   throttler.throttle([:mysqla, :mysqlb]) do
  #     update(batch)
  #   end
  # end
  # ```
  #
  # Before each call to `update(batch)` the throttler will call freno to
  # check the health of the `mysqla` and `mysqlb` stores on behalf of :my_app;
  # and sleep if any of the stores is not ok.
  #
  class Throttler

    attr_accessor :client,
                  :app,
                  :mapper,
                  :instrumenter,
                  :wait_seconds,
                  :max_wait_seconds

    # Initializes a new instance of the throttler
    #
    # In order to initialize a Throttler you need the following arguments:
    #
    #  - a `client`: a instance of Freno::Client
    #
    #  - an `app`: a symbol indicating the app-name for which Freno will respond
    #    checks.
    #
    # Also, you can optionally provide the following named arguments:
    #
    #  - `:mapper`: An object that responds to `call(context)` and returns a
    #     `Enumerable` of the store names for which we need to wait for
    #     replication delay. By default this is the `IdentityMapper`, which will
    #     check the stores given as context.
    #
    #     For example, if the `throttler` object used the default mapper:
    #
    #      ```
    #      throttler.throttle(:mysqlc) do
    #         update(batch)
    #      end
    #      ```
    #
    #  - `:instrumenter`: An object that responds to
    #     `instrument(event_name, context = {}, &block)` that can be used to
    #     add cross-cutting concerns like logging or stats to the throttler.
    #
    #     By default, the instrumenter is `Intrumenter::Noop`, which does
    #     nothing but yielding the block it receives.
    #
    #  - `:wait_seconds`: A positive float indicating the number of seconds the
    #     throttler will wait before checking again, in case some of the stores
    #     didn't catch-up the last time they were check.
    #
    #  - `:max_wait_seconds`: A positive float indicating the maxium number of
    #     seconds the throttler will wait in total for replicas to catch-up
    #     before raising a `WaitedTooLong` error.
    #
    def initialize(client: nil,
                    app: nil,
                    mapper: Mapper::Identity,
                    instrumenter: Instrumenter::Noop,
                    wait_seconds: 0.5,
                    max_wait_seconds: 10)

      @client           = client
      @app              = app
      @mapper           = mapper
      @instrumenter     = instrumenter
      @wait_seconds     = wait_seconds
      @max_wait_seconds = max_wait_seconds

      yield self if block_given?

      validate_args
    end

    # This method receives a context to infer the set of stores that it needs to
    # throttle writes to.
    #
    # With that information it asks freno whether all the stores are ok.
    # In case they are, it executes the given block.
    # Otherwise, it waits `wait_seconds` before trying again.
    #
    # In case the throttler has waited more than `max_wait_seconds`, it raises
    # a WaitedTooLong error.
    #
    # this method is instrumented, the instrumenter will receive the following
    # events:
    #
    # - "throttler.called" each time this method is called
    # - "throttler.succeeded" when the stores were ok, before yielding the block
    # - "throttler.waited" when the stores were not ok, after waiting
    #   `wait_seconds`
    # - "throttler.waited_too_long" when the stores were not ok, but the
    #   thottler already waited at least `max_wait_seconds`, right before
    #   raising `WaitedTooLong`
    # - "throttler.freno_errored" when there was an error with freno, before
    #   raising `ClientError`.
    #
    def throttle(context = nil)
      instrument(:called) do
        waited = 0

        while true do # rubocop:disable Lint/LiteralInCondition
          if all_stores_ok?(context)
            instrument(:succeeded, waited: waited)
            return yield
          end

          waited += wait
          instrument(:waited, waited: waited, max: max_wait_seconds)

          if waited > max_wait_seconds
            instrument(:waited_too_long, waited: waited, max: max_wait_seconds)
            raise WaitedTooLong.new(waited, max_wait_seconds)
          end
        end
      end
    end

    private

    def validate_args
      errors = []

      %i(client app mapper instrumenter
        wait_seconds max_wait_seconds).each do |argument|
        errors << "#{argument} must be provided" unless send(argument)
      end

      unless max_wait_seconds > wait_seconds
        errors << "max_wait_seconds (#{max_wait_seconds}) has to be greather than wait_seconds (#{wait_seconds})"
      end

      raise ArgumentError.new(errors.join("\n")) if errors.any?
    end

    def all_stores_ok?(context)
      store_names = mapper.call(context)

      store_names.all? do |store_name|
        client.check?(app: app, store_name: store_name)
      end
    rescue Freno::Error => e
      instrument(:freno_errored, error: e)
      raise ClientError.new(e)
    end

    def wait
      sleep wait_seconds
    end

    def instrument(event_name, payload = {}, &block)
      instrumenter.instrument("throttler.#{event_name}", payload, &block)
    end
  end
end
