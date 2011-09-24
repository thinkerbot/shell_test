module ShellTest
  module Pty
    # A timer to provide timeouts counting down to a specified stop time.
    class CountdownTimer

      # A clock used to determine current_time - normally the clock is simply
      # Time, but a different clock can be provided as needed.
      attr_reader :clock

      # The specified stop time
      attr_accessor :stop_time

      def initialize(clock=Time)
        @clock = clock
        @stop_time = 0
      end

      # Returns the current time as a Float.
      def current_time
        clock.now.to_f
      end

      # Sets the stop time to be current_time plus the specified numeric
      # timeout.
      def timeout=(timeout)
        @stop_time = timeout.nil? ? nil : current_time + timeout
      end

      # Returns the duration from current_time until stop_time.  If that
      # duration is less than zero, then 0 is returned.  If the stop_time is
      # nil, then timeout returns nil.
      def timeout
        if stop_time.nil?
          nil
        else
          timeout = stop_time - current_time
          timeout < 0 ? 0 : timeout
        end
      end
    end
  end
end