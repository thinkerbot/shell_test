require 'shell_test/timeout_timer'

module ShellTest
  class Agent
    class << self
      def run(cmd)
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            yield new(master, slave)
          rescue
            Process.kill(9, pid)
            raise
          ensure
            Process.wait(pid)
          end
        end
      end
    end

    attr_reader :master
    attr_reader :slave
    attr_reader :timer

    def initialize(master, slave, timer = TimeoutTimer.new)
      @master = master
      @slave  = slave
      @timer  = timer
    end

    def start_run(max_run_time)
      timer.start(max_run_time)
    end

    # Returns time elapsed
    def stop_run
      timer.stop
    end

    # Timeout:
    #
    #   pos - sets mark at current time + timeout (up to max_run_time)
    #   neg - preserves current mark
    #   nil - sets mark to end time
    #
    def expect(prompt, timeout=nil)
      timer.set_timeout(timeout)

      buffer = ''
      while true
        if !IO.select([slave],nil,nil,timer.timeout)
          raise TimeoutError, "waiting for: #{prompt.inspect}\n#{buffer.inspect}"
        end

        if slave.eof?
          break
        end

        # Use readpartial instead of read because it will not block if the
        # length is not fully available.
        #
        # Use readpartial+select instead of read_nonblock to avoid polling in
        # a tight loop.
        buffer << slave.readpartial(1024)

        if prompt && buffer =~ prompt
          break
        end
      end
      buffer
    end

    def write(input)
      master.print input
    end

    class TimeoutError < RuntimeError
    end
  end
end