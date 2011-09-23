require 'pty'
require 'shell_test/countdown_timer'

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

    # The timer managing timeouts.  The timer ensures that the timeouts used
    # by expect are never negative, or nil to indicate no timeout.  Timeouts
    # are set on the timer using `timer.timeout=` and retrieved via
    # `timer.timeout`.
    attr_accessor :timer

    def initialize(master, slave)
      @master = master
      @slave  = slave
      @timer  = CountdownTimer.new
    end

    # Reads from the slave until the regexp is matched and returns the
    # resulting string.  If a nil regexp is given then expect reads until the
    # slave eof.
    #
    # A timeout may be given.  If the slave doesn't produce the expected
    # string (or eof) within the timeout then expect raises an error.
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
      timer.timeout = timeout

      buffer = ''
      while true
        if !IO.select([slave],nil,nil,timer.timeout)
          raise TimeoutError.new(regexp, buffer)
        end

        if regexp.nil? && slave.eof?
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

    def close
      master.close unless master.closed?
      slave.close unless slave.closed?
    end

    class TimeoutError < RuntimeError
      attr_reader :regexp
      attr_reader :buffer
      def initialize(regexp, buffer)
        @regexp = regexp
        @buffer = buffer
        super "waiting for: #{regexp.inspect}\n#{buffer}"
      end
    end
  end
end