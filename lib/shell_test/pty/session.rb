require 'shell_test/pty/agent'
require 'shell_test/pty/utils'
require 'shell_test/pty/step_timer'
require 'strscan'

module ShellTest
  module Pty
    class Session
      include Utils

      attr_reader :shell
      attr_reader :env
      attr_reader :steps

      def initialize(shell='/bin/sh', env={})
        @shell = shell
        @env = {'PS1' => '$ ', 'PS2' => '> '}.merge(env)
        @steps = []
      end

      def on(prompt, input, timeout=nil, &callback)
        steps << [prompt, input, timeout, callback]
        self
      end

      # Parses an input string into steps.
      def parse(str, inline_regexp = /{{(.*?)}}/)
        scanner = StringScanner.new(str)
        promptr = /(#{ps1rs}|#{ps2rs}|#{inline_regexp})/

        while expected = scanner.scan_until(promptr)
          match = scanner[1]

          case match
          when env['PS1']
            prompt = ps1r
            input  = scanner.scan_until(/\n/)
          when env['PS2']
            prompt = ps2r
            input  = scanner.scan_until(/\n/)
          else
            expected = expected.chomp(match)
            start    = expected.rindex("\n") || 0
            length   = expected.length - start
            prompt   = /^#{expected[start, length]}\z/
            input    = scanner[2].to_s + scanner.scan_until(/\n/)
          end

          if block_given?
            on(prompt, input) {|actual| yield expected, actual }
          else
            on(prompt, input)
          end
        end
      end

      def ps1rs
        "^#{Regexp.escape(env['PS1'])}"
      end

      def ps2rs
        "^#{Regexp.escape(env['PS2'])}"
      end

      def ps1r
        /#{ps1rs}/
      end

      def ps2r
        /#{ps2rs}/
      end

      def run(opts={})
        opts = {:clock => Time, :max_run_time => 1}.merge(opts)
        timer = StepTimer.new(opts[:clock])

        with_env(env) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(opts[:max_run_time])

            unless opts[:crlf]
              # Use a partial_len > 1 as a minor optimization.  There is no
              # need to be precise (ultimately it's for readpartial).
              agent.expect(ps1r, 1, 32)
              agent.write "stty -onlcr\n"
              agent.expect(/\n/, 1, 32)
            end

            steps.each do |prompt, input, timeout, callback|
              buffer = agent.expect(prompt, timeout, 1024)

              if callback
                callback.call buffer
              end

              if block_given?
                yield buffer
              end

              if input
                agent.write(input)
              end
            end

            if block_given?
              yield agent.read
            end

            agent.close
            timer.stop
          end
        end
      end

      def capture(opts={})
        buffer = []
        run(opts) {|str| buffer << str }
        buffer.join
      end
    end
  end
end