require File.expand_path("../../test_helper", __FILE__)
require "shell_test/agent"

class AgentTest < Test::Unit::TestCase
  Agent = ShellTest::Agent

  attr_accessor :agent

  def setup
    super
    @agent = Agent.new(*IO.pipe.reverse)
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
    assert_equal "abcx", agent.expect(/x/, 1)
  end

  def test_expect_raises_error_if_regexp_is_not_matched_in_timeout
    agent.master << "abc"
    err = assert_raises(Agent::TimeoutError) { agent.expect(/x/, 0.1) }
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

    err = assert_raises(Agent::TimeoutError) do
      agent.expect(/x/, 0.3)
    end

    assert err.buffer =~ /\.+/
  end

  def test_expect_read_in_chunks_of_partial_len
    agent.master << "abcxyz"
    assert_equal "abcxy", agent.expect(/x/, 0.1, 5)
  end

  def test_expect_reads_to_eof_for_nil_regexp
    agent.master << "abcxyz"
    agent.master.close
    assert_equal "abcxyz", agent.expect(nil, 1)
  end

  def test_expect_raises_error_on_eof_if_regexp_has_not_matched
    agent.master << "abc"
    agent.master.close
    assert_raises(EOFError) { agent.expect(/x/, 1) }
  end
end