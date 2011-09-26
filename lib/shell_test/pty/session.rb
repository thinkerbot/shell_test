require 'shell_test/pty/agent'
require 'shell_test/pty/utils'
require 'shell_test/pty/step_timer'

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

      def on(prompt, input, timeout=nil)
        steps << [prompt, input, timeout]
        self
      end

      # Parses an input string into steps.
      def parse(str)
        
      end

      def run(opts={})
        opts = {:clock => Time, :max_run_time => 5}
        timer = StepTimer.new(opts[:clock])

        with_env(env) do
          spawn(shell) do |master, slave|
            agent = Agent.new(master, slave, :timer => timer, :partial_len => 1024)
            timer.start(opts[:max_run_time])

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

      def capture(opts={})
        buffer = []
        run(opts) {|str| buffer << str }
        buffer.join
      end
    end
  end
end