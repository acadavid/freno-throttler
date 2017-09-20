require "freno/throttler/version"
require "freno/throttler/errors"

module Freno
  class Throttler

    attr_accessor :client, :mapper, :app, :wait_seconds, :max_wait_seconds, :options

    def initialize(client, app, mapper, wait_seconds: 0.5, max_wait_seconds: 10, options: {})
      @client           = client
      @app              = app
      @mapper           = mapper
      @wait_seconds     = wait_seconds
      @max_wait_seconds = max_wait_seconds
      @options          = options
    end

    def throttle(context: nil)
      waited = 0
      while true do
        return yield if all_stores_caught_up?(context)
        waited += wait
        raise WaitedTooLong if waited > max_wait_seconds
      end
    end

    private

    def all_stores_caught_up?(context)
      store_names = mapper.call(context)

      store_names.all? do |store_name|
        client.check?(app: app, store_name: store_name)
      end
    rescue Freno::Error => e
      raise ClientError.new(e)
    end

    def wait
      sleep wait_seconds
    end
  end
end
