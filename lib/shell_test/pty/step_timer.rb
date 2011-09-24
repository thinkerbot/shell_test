module ShellTest
  module Pty
    class StepTimer
      attr_reader :clock
      attr_reader :start_time
      attr_reader :stop_time
      attr_reader :step_time

      def initialize(clock=Time)
        @clock = clock
        reset
      end

      def current_time
        clock.now.to_f
      end

      def reset
        @start_time = nil
        @stop_time  = nil
        @step_time  = 0
      end

      def start(max_run_time=60)
        reset
        @start_time = current_time
        @stop_time  = start_time + max_run_time
        @step_time  = stop_time
      end

      def running?
        start_time.nil? || stop_time.nil? ? false : true
      end

      def stop
        if running?
          elapsed_time = current_time - start_time
          reset
          elapsed_time
        else
          nil
        end
      end

      def timeout=(timeout)
        unless running?
          raise "cannot set timeout unless running"
        end

        case
        when timeout.nil?
          @step_time = stop_time
        when timeout < 0 
          step_time
        else
          mtime = current_time + timeout
          @step_time = mtime > stop_time ? stop_time : mtime
        end
      end

      def timeout
        timeout = step_time - current_time
        timeout < 0 ? 0 : timeout
      end
    end
  end
end