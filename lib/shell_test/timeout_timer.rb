module ShellTest
  class TimeoutTimer
    attr_reader :clock
    attr_reader :start_time
    attr_reader :stop_time
    attr_reader :mark_time

    def initialize(clock=Time)
      @clock = clock
      reset
    end

    def reset
      @start_time = 0
      @stop_time  = 0
      @mark_time  = 0
    end

    def start(max_run_time=60)
      reset
      @start_time = clock.now
      @stop_time  = start_time + max_run_time
      @mark_time  = stop_time
    end

    def stop
      elapsed_time = clock.now - start_time
      reset
      elapsed_time
    end

    def timeout=(timeout)
      case
      when timeout.nil?
        @mark_time = stop_time
      when timeout < 0 
        mark_time
      else
        mtime = clock.now + timeout
        @mark_time = mtime > stop_time ? stop_time : mtime
      end
    end

    def timeout
      timeout = mark_time - clock.now
      timeout < 0 ? 0 : timeout
    end
  end
end