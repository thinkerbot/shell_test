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

    def current_time
      clock.now
    end

    def reset
      @start_time = 0
      @stop_time  = 0
      @mark_time  = 0
    end

    def start(max_run_time=60)
      reset
      @start_time = current_time
      @stop_time  = start_time + max_run_time
      @mark_time  = stop_time
    end

    def stop
      elapsed_time = current_time - start_time
      reset
      elapsed_time
    end

    def set_timeout(duration)
      case
      when duration.nil?
        @mark_time = stop_time
      when duration < 0 
        mark_time
      else
        mtime = current_time + duration
        @mark_time = mtime > stop_time ? stop_time : mtime
      end
    end

    def timeout
      mark_time - current_time
    end
  end
end