module ShellTest
   class CountdownTimer
    attr_reader :duration
    attr_reader :start_time
    attr_reader :stop_time
    attr_reader :mark_time

    def initialize(duration)
      @duration = duration
      reset
    end

    def current_time
      Time.now.to_i
    end

    def reset
      @start_time = 0
      @stop_time  = 0
      @mark_time  = 0
    end

    def start
      reset
      @start_time = current_time
      @stop_time  = start_time + duration
      @mark_time  = stop_time
    end

    def stop
      elapsed_time = current_time - start_time
      reset
      elapsed_time
    end

    def time_to_stop
      stop_time - current_time
    end

    def set_mark(duration)
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

    def time_to_mark
      mark_time - current_time
    end
  end
end