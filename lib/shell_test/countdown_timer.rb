module ShellTest
   class CountdownTimer
    attr_reader :duration
    attr_reader :start_time
    attr_reader :finish_time
    attr_reader :mark_time

    def initialize(duration)
      @duration = duration
      reset
    end

    def current_time
      Time.now.to_i
    end

    def reset
      @start_time  = nil
      @finish_time = nil
      @mark_time   = nil
    end

    def start
      reset
      @start_time  = current_time
      @finish_time = start_time + duration
      @mark_time   = finish_time
    end

    def running?
      start_time != nil
    end

    def finish
      elapsed_time = start_time ? current_time - start_time : nil
      reset
      elapsed_time
    end

    def time_to_finish
      unless running?
        raise "timer is not running"
      end
      finish_time - current_time
    end

    def set_mark(duration)
      if duration.nil? || !running?
        return mark_time
      end

      mtime = current_time + duration
      @mark_time = mtime > finish_time ? finish_time : mtime
    end

    def time_to_mark
      unless running?
        raise "timer is not running"
      end
      mark_time - current_time
    end
  end
end