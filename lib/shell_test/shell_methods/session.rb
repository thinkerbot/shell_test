require 'shell_test/env_methods'
require 'shell_test/shell_methods/agent'
require 'shell_test/shell_methods/utils'
require 'strscan'

module ShellTest
  module ShellMethods
    
    # Session is an engine for running shell sessions.
    class Session
      include EnvMethods
      include Utils

      DEFAULT_SHELL = '/bin/sh'
      DEFAULT_PS1 = '$ '
      DEFULAT_PS2 = '> '

      attr_reader :shell
      attr_reader :ps1
      attr_reader :ps2
      attr_reader :stty
      attr_reader :timer
      attr_reader :steps
      attr_reader :log
      attr_reader :visual
      attr_reader :max_run_time
      attr_reader :status

      def initialize(options={})
        @shell = options[:shell] || DEFAULT_SHELL
        @ps1   = options[:ps1] || DEFAULT_PS1
        @ps2   = options[:ps2] || DEFULAT_PS2
        @stty  = options[:stty] || '-echo -onlcr'
        @timer = options[:timer] || Timer.new
        @visual  = options[:visual] || true
        @max_run_time = options[:max_run_time] || 1

        @ps1r    = /#{Regexp.escape(ps1)}/
        @ps2r    = /#{Regexp.escape(ps2)}/
        @promptr = /(#{@ps1r}|#{@ps2r}|\{\{(.*?)\}\})/
        @steps   = [[nil, nil, nil, nil]]
        @log     = []
        @status  = nil
      end

      def on(prompt, input=nil, max_run_time=nil, &callback)
        if prompt.nil? && !input.nil?
          raise "cannot provide input without a prompt: #{input.inspect}"
        end
        last = steps.last
        last[0] = prompt
        last[1] = input
        last[2] = max_run_time
        steps << [nil, nil, nil, callback]
        self
      end

      def split(str)
        scanner = StringScanner.new(str)

        args = []
        while output = scanner.scan_until(args.empty? ? /(#{@ps1r})/ : @promptr)
          match = scanner[1]
          input = scanner[2].to_s + scanner.scan_until(/\n/)

          max_run_time = -1
          input.sub!(/\#\s*\[(\d+(?:\.\d+)?)\].*$/) do
            max_run_time = $1.to_f
            nil
          end

          case match
          when ps1
            prompt = @ps1r
            if max_run_time == -1
              max_run_time = nil
            end
          when ps2
            prompt = @ps2r
          else
            output = output.chomp(match)
            start  = output.rindex("\n") || 0
            length = output.length - start
            prompt = /^#{output[start, length]}\z/
          end

          args << output
          args << prompt
          args << input
          args << max_run_time
        end

        args << scanner.rest
        args
      end

      # Parses a terminal snippet into steps that a Session can run, and adds
      # those steps to self.  The snippet should utilize ps1 and ps2 as set on
      # self.  If an exit command is not explicity given, then one is added.
      #
      #   session = Session.new
      #   session.parse %{
      #   $ echo abc
      #   abc
      #   }
      #   session.run.result   # => "$ echo abc\nabc\n$ exit $?\nexit\n"
      #
      # Steps are registered with a callback block, if given, to recieve the
      # expected and actual outputs during run.  Normally the callback is used
      # to validate that the run is going as planned.
      def parse(script, options={}, &block)
        args = split(script)
        args.shift # ignore script before first prompt

        if options[:noexit]
          args.pop
        else
          args.last << ps1
          args.concat [@ps1r, "exit $?\n", nil, nil]
        end

        while !args.empty?
          prompt = args.shift
          input  = args.shift
          max_run_time = args.shift
          output = args.shift
          callback = validator(output, args.first, &block)
          on(prompt, input, max_run_time, &callback)
        end

        self
      end

      def validator(output, next_prompt)
        return nil unless output && block_given?
        lambda do |actual|
          if visual
            output = reformat(output, next_prompt)
            actual = reformat(actual, next_prompt)
          end

          yield(self, output, actual)
        end
      end

      # Spawns a PTY shell session and yields an Agent to the block.  The
      # session is logged to log and the final exit status set into status
      # (any previous values are overwritten).
      #
      # ==== ENV variables
      #
      # PS1 and PS2 are set into ENV for the duration of the block and so in
      # most cases the shell inherits those values.  Keep in mind, however,
      # that the shell config scripts can set these variables and on some
      # distributions (ex SLES 10) the config script do not respect prior
      # values.
      #
      # ==== Exit and Expect
      #
      # Calling exit on a shell session allows the shell to communicate out an
      # exit status and to gracefully clean up.  This is a common motif:
      #
      #   agent.write "exit $?\n"
      #
      # However, beware the temptation to read beyond an exit - the behavior
      # of shell sessions after an exit varies dramatically from system to
      # system, and occasionally suffers from race conditions.  Don't do this:
      #
      #   agent.write "exit $?\n"
      #   agent.read(timeout)       # nor agent.expect(nil, timeout)
      #
      # On OS X (10.6.8) + 1.9.2 + bash this can cause intermittent timeouts
      # waiting for the EOF, but more commonly returns "exit\n".  Ubuntu
      # (11.04) + 1.8.7 + ksh does not timeout but instead reads nothing, or
      # sometimes just a few characters like "exi". Save yourself. Write the
      # exit, abandon further reads, and let spawn wait for the session to
      # end.
      def spawn
        with_env('PS1' => ps1, 'PS2' => ps2) do
          @log = []
          @status = super(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(max_run_time)

            begin
              yield agent
            rescue Agent::ReadError
              log << $!.buffer
              $!.message << "\n#{summary}"
              raise
            end

            timer.stop
            agent.close
          end
        end
        self
      end

      def run
        spawn do |agent|
          if stty
            agent.expect(@ps1r, 1)
            agent.write "stty #{stty}\n"

            # Expect ps1 a second time to clear the stty echo from the
            # slave. Note ps1 + \n is more reliable than expecting the
            # newline at the end of the stty.
            agent.expect(@ps1r, 1)
            agent.write "\n"
          end

          timeout  = nil
          steps.each do |prompt, input, max_run_time, callback|
            buffer = agent.expect(prompt, timeout)

            if prompt
              log << buffer
            end

            if callback
              callback.call buffer
            end

            if input
              log << input
              agent.write(input)
            end

            timeout = max_run_time
          end
        end
      end

      # Returns what would appear to the user at the current point in the
      # session (with granularity of an input/output step).
      #
      # Currently result ONLY works as intended when stty is set to turn off
      # input echo and output carriage returns, either with '-echo -onlcr'
      # (the default) or 'raw'.  Otherwise the inputs can appear twice in the
      # result and there will be inconsistent end-of-lines.
      def result
        log.join
      end

      # Formats the status of self into a string. A format string can be
      # provided - it is evaluated using '%' using arguments: [shell,
      # elapsed_time, result]
      def summary(format=nil)
        (format || %Q{
%s (%.2fs)
=========================================================
%s
=========================================================
}) % [shell, timer.elapsed_time, result]
      end

      private

      # helper to make session output more useful to debugging eyes
      # * trim the prompt of the end, if present
      # * make non-printable chars visible
      def reformat(str, regexp)
        str = trim(str, regexp)
        escape_non_printable_chars(str)
      end
    end
  end
end