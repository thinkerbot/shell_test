require 'shell_test/shell_methods/agent'
require 'shell_test/shell_methods/parser'
require 'shell_test/shell_methods/utils'

module ShellTest
  module ShellMethods
    class Session
      class << self
        def run(shell, script, options={})
          session = new(shell, options)

          last_input = ''
          session.parse(script).each do |output, input, prompt, max_run_time|
            session.on(prompt, input, max_run_time) do |actual|

              # clean unless raw output is desired
              # unless raw
              #   output = parser.strip(output, input, prompt)
              #   actual = parser.strip(actual, input, prompt)
              # end

              yield("#{last_input}#{output}", actual, input)
              last_input = input
            end
          end
          session.close
          session.run(options)
        end
      end

      include Utils

      attr_reader :shell
      attr_reader :env
      attr_reader :parser
      attr_reader :steps

      def initialize(shell='/bin/sh', env={})
        @shell = shell
        @env = {'PS1' => '$ ', 'PS2' => '> '}.merge(env)
        @parser = Parser.new(@env.dup)
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

      def parse(script)
        parser.parse(script)
      end

      def close
        unless closed?
          on parser.ps1r,  "exit $?\n"
        end
      end

      def closed?
        next_to_last_input = steps[-2][1]
        next_to_last_input && next_to_last_input =~ /^exit /
      end

      def run(opts={})
        opts = {:clock => Time, :max_run_time => 1}.merge(opts)
        timer = Timer.new(opts[:clock])

        with_env(env) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer)
            timer.start(opts[:max_run_time])

            unless opts[:crlf]
              # Use a partial_len > 1 as a minor optimization.  There is no
              # need to be precise (ultimately it's for readpartial).
              agent.expect(parser.ps1r, 1, 32)
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