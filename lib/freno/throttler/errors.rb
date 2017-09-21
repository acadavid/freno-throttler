require "freno/client"

module Freno
  class Throttler

    # Any throttler-related error.
    class Error < Freno::Error; end

    # Raised if the throttler has waited too long for replication delay
    # to catch up.
    class WaitedTooLong < Error
      def initialize(waited_seconds, max_wait_seconds)
        super("Waited #{waited_seconds} seconds. Max allowed was #{max_wait_seconds} seconds")
      end
    end

    # Raised if the freno client errored.
    class ClientError < Error; end
  end
end
