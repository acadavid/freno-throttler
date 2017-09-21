require "freno/throttler/version"
require "freno/throttler/instrumenter"
require "freno/throttler/errors"

module Freno
  class Throttler

    attr_accessor :client, :app, :mapper, :instrumenter, :wait_seconds, :max_wait_seconds, :options

    def initialize(client, app, mapper, instrumenter: Instrumenter::Noop,  wait_seconds: 0.5, max_wait_seconds: 10, options: {})
      @client           = client
      @app              = app
      @mapper           = mapper
      @instrumenter     = instrumenter
      @wait_seconds     = wait_seconds
      @max_wait_seconds = max_wait_seconds
      @options          = options

      yield self if block_given?
    end

    def throttle(context: nil)
      instrument(:called) do
        waited = 0

        while true do
          if all_stores_caught_up?(context)
            instrument(:succeeded, waited: waited)
            return yield
          end

          waited += wait
          instrument(:waited, waited: waited, max: max_wait_seconds)

          if waited > max_wait_seconds
            instrument(:waited_too_long, waited: waited, max: max_wait_seconds)
            raise WaitedTooLong
          end
        end
      end
    end

    private

    def all_stores_caught_up?(context)
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
      instrumenter.instrument("throttler.#{event_name}", &block)
    end
  end
end
