require "freno/client"

module Freno
  class Throttler
    # Public: any throttler-related error.
    class Error < Freno::Error; end

    # Public: raised if the throttler has waited too long for replication delay
    # to catch up.
    class WaitedTooLong < Error; end

    # Public: raised if the freno client errored.
    class ClientError < Error; end
  end
end
