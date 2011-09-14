require 'shell_test/timeout_timer'

module ShellTest
  class Agent
    attr_reader :stdin
    attr_reader :stdout
    attr_reader :timer

    def initialize(stdin, stdout)
      @stdin  = stdin
      @stdout = stdout
      @timer  = TimeoutTimer.new
    end

    def start_run(max_run_time)
      timer.start(max_run_time)
    end

    def run(steps)
      steps.each do |prompt, input, timeout, callback|
        buffer = read_until(prompt)

        if block_given?
          yield buffer
        end

        if callback
          callback.call(buffer)
        end

        if input
          stdout.print input
        end
      end
    end

    def stop_run
      if block_given?
        buffer = read_until(nil)
        yield buffer
      end

      timer.stop # returns time elapsed
    end

    def read_until(prompt, timeout=nil)
      # pos - sets mark at current time + timeout (up to max)
      # neg - preserves current mark
      # nil - sets mark to end time
      timer.set_timeout(timeout)

      buffer = ''
      while true
        if !IO.select([stdin],nil,nil,timer.timeout)
          raise TimeoutError, "waiting for: #{prompt.inspect}\n#{buffer.inspect}"
        end

        if stdin.eof?
          break
        end

        # Use readpartial instead of read because it will not block if the
        # length is not fully available.
        #
        # Use readpartial+select instead of read_nonblock to avoid polling
        # in a tight loop.
        buffer << stdin.readpartial(1024)

        if prompt && buffer =~ prompt
          break
        end
      end
      buffer
    end

    class TimeoutError < RuntimeError
    end
  end
end