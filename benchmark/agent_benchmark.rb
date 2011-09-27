require 'shell_test/pty/agent'
require 'shell_test/pty/utils'
require 'benchmark'

def run_cmd
  %{ruby -e "8.times { puts '.' * 1000 }; puts '?'"}
end

def run_agent(partial_len)
  ShellTest::Pty::Utils.spawn(run_cmd) do |master, slave|
    agent = ShellTest::Pty::Agent.new(master, slave, :partial_len => partial_len)
    agent.expect(/\?/, nil)
    agent.close
  end
end

Benchmark.benchmark("expect speed vs partial_len\n", 10) do |x|
  n = 10

  x.report('1') do
    n.times { run_agent(1) }
  end

  x.report('1024') do
    n.times { run_agent(1024) }
  end

  x.report('4096') do
    n.times { run_agent(4096) }
  end

  x.report('backticks') do
    n.times { `#{run_cmd}` }
  end
end
