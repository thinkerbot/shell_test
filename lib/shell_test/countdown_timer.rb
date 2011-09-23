module ShellTest
  # A timer to provide timeouts counting down to a specified stop time.
  class CountdownTimer

    # A clock used to determine now - normally the clock is simply Time, but a
    # different clock can be provided as needed.
    attr_reader :clock

    # The specified stop time
    attr_accessor :stop_time

    def initialize(clock=Time)
      @clock = clock
      @stop_time = 0
    end

    # Sets the stop time to be now plus the specified timeout.
    def timeout=(timeout)
      @stop_time = timeout.nil? ? nil : clock.now + timeout
    end

    # Returns the duration from now until the stop time.  If that duration is
    # less than zero, then 0 is returned.  If the stop time is nil, then
    # timeout returns nil.
    def timeout
      if stop_time.nil?
        nil
      else
        timeout = stop_time - clock.now
        timeout < 0 ? 0 : timeout
      end
    end
  end
end