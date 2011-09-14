require 'shell_test/agent'
require 'pty'

module ShellTest
  class Session
    attr_reader :cmd
    attr_reader :steps
    attr_reader :prompts

    def initialize(cmd, prompts={})
      @cmd = cmd
      @steps = []
      @prompts = {}
      prompts.each_pair {|key, value| register(key, value) }
    end

    def register(prompt, pattern=prompt)
      unless pattern.kind_of?(Regexp)
        pattern = Regexp.new pattern.to_s
      end
      prompts[prompt] = pattern
    end

    def resolve_prompt(prompt)
      prompts[prompt] || Regexp.new(prompt.to_s)
    end

    def on(prompt, input, timeout=nil, &callback)
      steps << [resolve_prompt(prompt), input, timeout, callback]
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