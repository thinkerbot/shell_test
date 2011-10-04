require 'shell_test/env_methods'
require 'shell_test/shell_methods/agent'
require 'shell_test/shell_methods/utils'
require 'strscan'

module ShellTest
  module ShellMethods
    class Session
      include EnvMethods
      include Utils

      DEFAULT_SHELL = '/bin/sh'
      DEFAULT_PS1 = '$ '
      DEFULAT_PS2 = '> '

      attr_reader :shell
      attr_reader :ps1
      attr_reader :ps2
      attr_reader :steps

      def initialize(options={})
        @shell = options[:shell] || DEFAULT_SHELL
        @ps1   = options[:ps1] || DEFAULT_PS1
        @ps2   = options[:ps2] || DEFULAT_PS2

        @ps1r    = /#{Regexp.escape(ps1)}/
        @ps2r    = /#{Regexp.escape(ps2)}/
        @promptr = /(#{@ps1r}|#{@ps2r}|\{\{(.*?)\}\})/

        @steps = [[nil, nil, nil, nil]]
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

      def parse(script, opts={})
        trim_prompt = opts[:trim]

        split(script).each do |output, input, prompt, max_run_time|
          if block_given?
            on(prompt, input, max_run_time) do |actual, cmd|

              if trim_prompt && prompt
                output = trim(output, prompt)
                actual = trim(actual, prompt)
              end

              yield(output, actual, cmd)
            end
          else
            on(prompt, input, max_run_time)
          end
        end
      end

      def run(opts={})
        opts  = {:clock => Time, :max_run_time => 1, :stty => nil}.merge(opts)
        timer = Timer.new(opts[:clock])

        with_env('PS1' => ps1, 'PS2' => ps2) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(opts[:max_run_time])

            if stty = opts[:stty]
              # Use a partial_len > 1 as a minor optimization.  There is no
              # need to be precise (ultimately it's for readpartial).
              agent.expect(@ps1r, 1, 32)
              agent.write "stty #{stty}\n"
              agent.expect(/\n/, 1, 32)
            end

            steps.each do |prompt, input, timeout, callback|
              buffer = agent.expect(prompt, timeout, 1024)

              if callback
                callback.call buffer, input
              end

              if block_given?
                yield buffer, input
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
        run(opts) {|output, input| buffer << output }
        buffer.join
      end
    end
  end
end