module Freno
  class Throttler
    module Instrumenter

      # Any instrumenter is an object that responds to
      # `instrument(event_name, payload = {})` to receive events from the
      # throttler.
      #
      # As an example, one could provide ActiveSupport::Notifications as an
      # instrumenter to publish events in the ActiveSupport::Notifications
      # system, that can be subcribed somewherelese in rails applications.
      #
      # The Noop instrumenter does nothing but yielding the control to the block
      # given if it is provided, and it's used as the default `:instrumenter`
      # for a throttler instance.
      #
      class Noop
        def self.instrument(event_name, payload = {})
          yield payload if block_given?
        end
      end
    end
  end
end
