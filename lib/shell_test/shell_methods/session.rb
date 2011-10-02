require 'shell_test/env_methods'
require 'shell_test/shell_methods/agent'
require 'shell_test/shell_methods/utils'
require 'strscan'

module ShellTest
  module ShellMethods
    class Session
      include EnvMethods
      include Utils

      attr_reader :shell
      attr_reader :env
      attr_reader :parser
      attr_reader :steps
      attr_reader :ps1
      attr_reader :ps2
      attr_reader :ps1r
      attr_reader :ps2r
      attr_reader :stty

      def initialize(options={})
        @shell = options[:shell] || '/bin/sh'
        @env   = options[:env] || {}
        @env['PS1'] ||= '$ '
        @env['PS2'] ||= '> '
        @stty  = options[:stty] || nil

        @ps1 = @env['PS1']
        @ps1r = /#{Regexp.escape(@ps1)}/
        @ps2 = @env['PS2']
        @ps2r = /#{Regexp.escape(@ps2)}/
        @promptr = /(#{@ps1r}|#{@ps2r}|{{(.*?)}})/
        @steps = [[nil, nil, nil, nil]]
      end

      def ssteps
        steps.collect {|s| s[0,3]}
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

      def parse(script)
        last_input = ''
        split(script).each do |output, input, prompt, max_run_time|
          on(prompt, input, max_run_time) do |actual|

            # clean unless raw output is desired
            # unless raw
            #   output = parser.strip(output, input, prompt)
            #   actual = parser.strip(actual, input, prompt)
            # end
            # puts last_input.scan(/.{0,80}/).inspect

            yield(output, actual, input)
            last_input = input
          end
        end
      end

      def run(opts={})
        opts = {:clock => Time, :max_run_time => 1}.merge(opts)
        timer = Timer.new(opts[:clock])

        with_env(env) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(opts[:max_run_time])

            if stty
              # Use a partial_len > 1 as a minor optimization.  There is no
              # need to be precise (ultimately it's for readpartial).
              agent.expect(@ps1r, 1, 32)
              agent.write "stty #{stty}\n"
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