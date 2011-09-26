require 'shell_test/pty/agent'
require 'shell_test/pty/utils'
require 'shell_test/pty/step_timer'

module ShellTest
  module Pty
    class Session
      include Utils

      attr_reader :shell
      attr_reader :steps
      attr_reader :opts

      def initialize(shell='/bin/sh', opts={})
        @shell = shell
        @steps = []
        @opts = {
          :ps1 => '$ ', :ps2 => '> ',
          :partial_len => 1024,
          :clock => Time
        }
      end

      def on(prompt, input, timeout=nil)
        steps << [prompt, input, timeout]
        self
      end

      # Parses an input string into steps.
      def parse(str)
        
      end

      def run(max_run_time=1)
        timer = StepTimer.new(opts[:clock])
        attrs = {
          :timer => timer, 
          :partial_len => opts[:partial_len]
        }
        env = {
          'PS1' => opts[:ps1],
          'PS2' => opts[:ps2]
        }

        with_env(env) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, opts)
            timer.start(max_run_time)

            steps.each do |prompt, input, timeout|
              buffer = agent.expect(prompt, timeout)

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

      def capture(max_run_time=1)
        buffer = []
        run(max_run_time) {|str| buffer << str }
        buffer.join
      end
    end
  end
end