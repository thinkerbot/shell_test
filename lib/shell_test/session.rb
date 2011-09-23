require 'shell_test/agent'
require 'pty'

module ShellTest
  class Session
    attr_reader :cmd
    attr_reader :steps

    def initialize(cmd)
      @cmd = cmd
      @steps = []
    end

    def on(prompt, input, timeout=nil, &callback)
      steps << [prompt, input, timeout, callback]
      self
    end

    def run(max_run_time=1)
      Agent.run(cmd) do |agent|
        agent.timer.start(max_run_time)

        steps.each do |prompt, input, timeout, callback|
          buffer = agent.expect(prompt, timeout)

          if block_given?
            yield buffer
          end

          if callback
            callback.call(buffer)
          end

          if input
            agent.write(input)
          end
        end

        if block_given?
          buffer = agent.expect(nil)
          yield buffer
        end

        agent.timer.stop
      end
    end
  end
end