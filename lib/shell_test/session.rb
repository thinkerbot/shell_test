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

    def run(max_run_time=1, &block)
      PTY.spawn(cmd) do |stdin,stdout,pid|
        begin
          agent = Agent.new(stdin, stdout)
          agent.start_run(max_run_time)
          agent.run(steps, &block)
          agent.stop_run(&block)
        rescue
          Process.kill(9, pid)
          raise
        ensure
          Process.wait(pid)
        end
      end
    end
  end
end