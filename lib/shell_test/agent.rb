require 'shell_test/timeout_timer'
require 'pty'

module ShellTest
  class Agent
    class << self
      # Spawns a PTY session and yields an Agent for that session to the
      # block. Run ensures the PTY process is killed upon errors, and but
      # re-raises the error for additional handling.  Lastly, run sets the
      # command status to $? upon completion.
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

    # The pty master
    attr_reader :master

    # The pty slave
    attr_reader :slave

    # A timer tracking timeouts
    attr_reader :timer

    def initialize(master, slave, timer = TimeoutTimer.new)
      @master = master
      @slave  = slave
      @timer  = timer
    end

    # Reads from the slave until the regexp is matched and returns the
    # resulting string.  If a nil regexp is given then expect reads until the
    # slave eof.
    #
    # A timeout may be given.  If the slave doesn't produce the expected
    # string (or eof) within the timeout then expect raises an error.
    #
    # ==== Timeout
    #
    # The timeout is designed to allow incremental timeouts in a multi-step
    # sessions, bounded by a maximum run time (see start_run).  As such the
    # timeout actually defines a mark and the effective timeout is the time to
    # that mark.
    #
    #   timeout value   effect
    #   positive        sets mark at current time + timeout (up to max_run_time)
    #   negative        preserves current mark
    #   nil             sets mark to end time
    #
    # ==== Partial Length
    #
    # A larger partial length may be specified to speed up expect when the
    # regexp is intended to match strings at a point where the slave will run
    # out of data, for example prompts where the pty waits for input.
    #
    # Note that used inappropriately this may result in more data being read
    # from the slave than is necessary to match the regexp.
    #
    def expect(regexp, timeout=nil, partial_len=1)
      timer.set_timeout(timeout)

      buffer = ''
      while true
        if !IO.select([slave],nil,nil,timer.timeout)
          raise TimeoutError, "waiting for: #{regexp.inspect}\n#{buffer}"
        end

        if slave.eof?
          break
        end

        # Use readpartial instead of read because it will not block if the
        # length is not fully available.
        #
        # Use readpartial+select instead of read_nonblock to avoid polling in
        # a tight loop.
        buffer << slave.readpartial(partial_len)

        if regexp && buffer =~ regexp
          break
        end
      end
      buffer
    end

    # Writes to the master.
    def write(input)
      master.print input
    end

    class TimeoutError < RuntimeError
    end
  end
end