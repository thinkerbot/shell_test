require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/agent"

# A timer to provide timeouts counting down to a specified stop time.
class CountdownTimer

  # A clock used to determine current_time - normally the clock is simply
  # Time, but a different clock can be provided as needed.
  attr_reader :clock

  # The specified stop time
  attr_accessor :stop_time

  def initialize(clock=Time)
    @clock = clock
    @stop_time = 0
  end

  # Returns the current time as a Float.
  def current_time
    clock.now.to_f
  end

  # Sets the stop time to be current_time plus the specified numeric
  # timeout.
  def timeout=(timeout)
    @stop_time = timeout.nil? ? nil : current_time + timeout
  end

  # Returns the duration from current_time until stop_time.  If that
  # duration is less than zero, then 0 is returned.  If the stop_time is
  # nil, then timeout returns nil.
  def timeout
    if stop_time.nil?
      nil
    else
      timeout = stop_time - current_time
      timeout < 0 ? 0 : timeout
    end
  end
end

class AgentTest < Test::Unit::TestCase
  Agent = ShellTest::ShellMethods::Agent

  attr_accessor :agent

  def setup
    super
    slave, master = IO.pipe
    @agent = Agent.new(master, slave, CountdownTimer.new)
  end

  def teardown
    @agent.close
    super
  end

  #
  # expect test
  #

  def test_expect_reads_until_regexp_matches
    agent.master << "abcxyz"
    assert_equal "abcx", agent.expect(/x/, 0.1)
  end

  def test_expect_raises_error_if_regexp_is_not_matched_in_timeout
    agent.master << "abc"
    err = assert_raises(Agent::ReadError) { agent.expect(/x/, 0.1) }

    assert_match(/timeout waiting for \/x\//, err.message)
    assert_equal "abc", err.buffer
  end

  def test_expect_does_not_refresh_timeout_on_new_content
    Thread.new do
      5.times do
        agent.master << '.'
        sleep 0.1
      end
      agent.master << 'x'
    end

    err = assert_raises(Agent::ReadError) do
      agent.expect(/x/, 0.3)
    end

    assert_match(/timeout waiting for \/x\//, err.message)
    assert err.buffer =~ /\.+/
  end

  def test_expect_reads_to_eof_for_nil_regexp
    agent.master << "abcxyz"
    agent.master.close
    assert_equal "abcxyz", agent.expect(nil, 0.1)
  end

  def test_expect_converts_strings_to_prompt_regexps
    agent.master << "abc$ xyz"
    assert_equal "abc$ ", agent.expect("$ ", 0.1)
  end

  def test_expect_raises_error_on_eof_if_regexp_has_not_matched
    agent.master << "abc"
    agent.master.close

    err = assert_raises(Agent::ReadError) { agent.expect(/x/, 0.1) }
    assert_equal "end of file reached", err.message
    assert_equal "abc", err.buffer
  end

  #
  # read test
  #

  def test_read_reads_to_the_end_of_slave
    agent.master << "abc"
    agent.master.close
    assert_equal "abc", agent.read(0.1)
  end

  def test_read_raises_error_if_eof_is_not_reached_in_timeout
    agent.master << "abc"
    err = assert_raises(Agent::ReadError) { agent.read(0.1) }

    assert_match(/timeout waiting for EOF/, err.message)
    assert_equal "abc", err.buffer
  end

  #
  # write test
  #

  def test_write_writes_str_to_master
    agent.write "abc"
    assert_equal "abc", agent.slave.read(3)
  end

  def test_write_raises_error_if_master_is_not_vailable_within_timeout
    err = assert_raises(Agent::WriteError) do
      # Not knowing the exact size of the master, just do this a bunch of
      # times until the master fills up and blocks.
      65536.times { agent.write('abc', 0.1) }
    end
    assert_equal "timeout waiting for master", err.message
  end

  #
  # close test
  #

  def test_close_closes_master_and_slave
    agent.close
    assert_equal true, agent.master.closed?
    assert_equal true, agent.slave.closed?
  end
end