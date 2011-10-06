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
      attr_reader :mode
      attr_reader :max_run_time

      def initialize(options={})
        @shell = options[:shell] || DEFAULT_SHELL
        @ps1   = options[:ps1] || DEFAULT_PS1
        @ps2   = options[:ps2] || DEFULAT_PS2
        @stty  = options[:stty] || '-echo -onlcr'
        @timer = options[:timer] || Timer.new
        @mode  = options[:mode] || {}
        @max_run_time = options[:max_run_time] || 1

        @ps1r    = /#{Regexp.escape(ps1)}/
        @ps2r    = /#{Regexp.escape(ps2)}/
        @promptr = /(#{@ps1r}|#{@ps2r}|\{\{(.*?)\}\})/
        @steps   = [[nil, nil, nil, nil]]
        @log     = []
      end

      def on(prompt, input, max_run_time=nil, &callback)
        last = steps.last

        if prompt.nil?
          unless input.nil?
            raise "cannot provide input without a prompt: #{input.inspect}"
          end
          last[2] = max_run_time
        else
          last[0] = prompt
          last[1] = input
          steps << [nil, nil, max_run_time, nil]
        end

        last[3] = callback
        self
      end

      def split(str)
        scanner = StringScanner.new(str)
        scanner.scan(/\s+/)

        steps   = []
        last_max_run_time = nil
        while output = scanner.scan_until(@promptr)
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

          steps << [output, input, prompt, last_max_run_time]
          last_max_run_time = max_run_time
        end

        if steps.empty?
          input  = scanner.scan(/.+?\n/)
          output = scanner.rest
          steps << [output + ps1, input, @ps1r, nil]
        else
          steps << [scanner.rest, nil, nil, last_max_run_time]
        end

        unless steps.length > 1 && steps[-2][1] =~ /^exit(?:$|\s)/
          last_step     = steps[-1]
          last_step[0] += ps1
          last_step[1]  = "exit $?\n"
          last_step[2]  = @ps1r
          steps << ["exit\n", nil, nil, nil]
        end

        steps
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
      def parse(script)
        split(script).each do |output, input, prompt, max_run_time|
          if block_given?
            on(prompt, input, max_run_time) do |actual|

              if mode[:rm_prompt] && prompt
                output = trim(output, prompt)
                actual = trim(actual, prompt)
              end

              if mode[:rm_cr]
                output = cr(output)
                actual = cr(actual)
              end

              output = bs(output)
              actual = bs(actual)
              output = bell(output)
              actual = bell(actual)

              yield(self, output, actual)
            end
          else
            on(prompt, input, max_run_time)
          end
        end
      end

      def run
        log.clear

        with_env('PS1' => ps1, 'PS2' => ps2) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(max_run_time)

            begin
              if stty
                # Use a partial_len > 1 as a minor optimization.  There is no
                # need to be precise (ultimately it's for readpartial).
                agent.expect(@ps1r, 1, 32)
                agent.write "stty #{stty}\n"
                agent.expect(/\n/, 1, 32)
              end

              steps.each do |prompt, input, timeout, callback|
                buffer = agent.expect(prompt, timeout, 1024)
                log << buffer

                if callback
                  callback.call buffer
                end

                if input
                  log << input
                  agent.write(input)
                end
              end
            rescue Agent::UnsatisfiedError
              log << $!.buffer
              $!.message << "\n#{status}"
              raise
            end

            agent.close
            timer.stop
          end
        end

        self
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
      def status(format=nil)
        (format || %Q{
%s (%.2fs)
=========================================================
%s
=========================================================
}) % [shell, timer.elapsed_time, result]
      end
    end
  end
end