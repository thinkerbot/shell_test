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
      DEFAULT_ENV   = {'PS1' => '$ ', 'PS2' => '> '}
      DEFAULT_STTY  = '-echo -onlcr'
      DEFAULT_MAX_RUN_TIME = 1

      # The session shell
      attr_reader :shell

      # The initial session ENV (as established by the parent ruby process -
      # note the shell init scripts can override it before the first prompt)
      attr_reader :env

      # Aguments string passed stty on run
      attr_reader :stty

      # The session timer, used by agents to determine timeouts
      attr_reader :timer

      # The maximum run time for the session
      attr_reader :max_run_time

      # An array of entries like [prompt, input, max_run_time, callback] that
      # indicate each step of a session.  See the on method for adding steps.
      attr_reader :steps

      # A log of the output at each step (set during run)
      attr_reader :log

      # A Process::Status for the session (set by run)
      attr_reader :status

      def initialize(options={})
        @shell = options[:shell] || DEFAULT_SHELL
        @env   = DEFAULT_ENV.merge(options[:env] || {})
        @stty  = options[:stty]  || DEFAULT_STTY
        @timer = options[:timer] || Timer.new
        @max_run_time = options[:max_run_time] || DEFAULT_MAX_RUN_TIME
        @steps   = [[nil, nil, nil, nil]]
        @log     = []
        @status  = nil
        @prompts = {
          :ps1 => /#{Regexp.escape(ps1)}/,
          :ps2 => /#{Regexp.escape(ps2)}/
        }
      end

      # The shell PS1, as configured in env.
      def ps1
        env['PS1']
      end

      # The shell PS2, as configured in env.
      def ps2
        env['PS2']
      end

      # Define a step.  At each step:
      #
      # 1. The session waits until the prompt is matched
      # 2. The input is written to the shell (if given)
      # 3. The output passed to the callback (if given)
      #
      # If the next prompt (or an EOF if there is no next prompt) is not
      # reached within max_run_time then a ReadError occurs.  Special
      # considerations:
      #
      # * The prompt should be a regular expression, :ps1, or :ps2.
      # * A nil max_run_time indicates no maximum run time - which more
      #   accurately means the input can go until the overall max_run_time for
      #   the session runs out.
      # * The output passed to the callback will include the string matched by
      #   the next prompt, if present.
      #
      # Returns self.
      def on(prompt, input=nil, max_run_time=nil, &callback) # :yields: output
        if prompt.nil?
          raise ArgumentError, "no prompt specified"
        end

        # Stagger assignment of step arguments so that the callback will be
        # recieve the output of the input. Not only is this more intuitive, it
        # ensures the last step will read to EOF (which expedites waiting on
        # the session to terminate).
        last = steps.last
        last[0] = prompt
        last[1] = input
        last[2] = max_run_time

        steps << [nil, nil, nil, callback]
        self
      end

      def split(str)
        scanner = StringScanner.new(str)
        scanner.scan_until(/(#{@prompts[:ps1]})/)
        scanner.pos -= scanner[1].to_s.length

        args = []
        while output = scanner.scan_until(/(#{@prompts[:ps1]}|#{@prompts[:ps2]}|\{\{(.*?)\}\})/)
          match = scanner[1]
          input = scanner[2] ? "#{scanner[2]}\n" : scanner.scan_until(/\n/)

          max_run_time = -1
          input.sub!(/\#\s*\[(\d+(?:\.\d+)?)\].*$/) do
            max_run_time = $1.to_f
            nil
          end

          case match
          when ps1
            prompt = :ps1
            if max_run_time == -1
              max_run_time = nil
            end
          when ps2
            prompt = :ps2
          else
            output = output.chomp(match)
            prompt = /^#{output.split("\n").last}\z/
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
      # self. An exit command is added unless the :noexit option is set to
      # true.
      #
      #   session = Session.new
      #   session.parse %{
      #   $ echo abc
      #   abc
      #   }
      #   session.run.result   # => "$ echo abc\nabc\n$ exit\nexit\n"
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
          args.concat [:ps1, "exit\n", nil, nil]
        end

        while !args.empty?
          prompt = args.shift
          input  = args.shift
          max_run_time = args.shift
          output = args.shift
          callback = make_callback(output, &block)

          on(prompt, input, max_run_time, &callback)
        end

        self
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
      def spawn
        with_env(env) do
          @log = []
          @status = super(shell) do |master, slave|
            agent = Agent.new(master, slave, timer, @prompts)
            timer.start(max_run_time)

            if stty
              # It would be lovely to work this into steps somehow, or to set
              # the stty externally like:
              #
              #   system("stty #{stty} < '#{master.path}'")
              #
              # Unfortunately the former complicates result and the latter
              # doesn't work.  In tests the stty settings DO get set but they
              # don't refresh in the pty.
              log << agent.on(:ps1, "stty #{stty}\n")
              log << agent.on(:ps1, "echo $?\n")
              log << agent.on(:ps1, "\n")

              unless log.last == "0\n#{ps1}"
                raise "stty failure\n#{summary}"
              end

              log.clear
            end

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

      # Runs each of steps within a shell session and collects the
      # inputs/outputs into log. After run the exit status of the session is
      # set into status.
      def run
        spawn do |agent|
          timeout  = nil
          steps.each do |prompt, input, max_run_time, callback|
            buffer = agent.expect(prompt, timeout)
            log << buffer

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
%s (elapsed: %.2fs max: %.2fs)
=========================================================
%s
=========================================================
}) % [shell, timer.elapsed_time, max_run_time, result]
      end

      private

      # helper to make a callback for validating output
      def make_callback(output) # :nodoc:
        if output && block_given?
          lambda do |actual|
            yield(self, output, actual)
          end
        else
          nil
        end
      end
    end
  end
end