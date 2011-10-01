require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/session"

class SessionTest < Test::Unit::TestCase
  Session = ShellTest::ShellMethods::Session

  attr_accessor :session

  def setup
    super
    @session = Session.new
  end

  #
  # capture test
  #

  def test_capture_captures_output_and_sets_exit_status
    session.on(/\$ /, "echo hello world\n")
    session.on(/\$ /, "exit 8\n")

    assert_equal "$ echo hello world\nhello world\n$ exit 8\nexit\n", session.capture
    assert_equal 8, $?.exitstatus
  end

  def test_capture_preserves_crlf_if_specified
    session.on(/\$ /, "exit\n")

    assert_equal "$ exit\r\nexit\r\n", session.capture(:crlf => true)
    assert_equal 0, $?.exitstatus
  end

  def test_capture_for_multiline_commands
    session.on(/\$ /, "echo ab\\\n")
    session.on(/\> /, "c\n")
    session.on(/\$ /, "exit\n")

    assert_equal "$ echo ab\\\n> c\nabc\n$ exit\nexit\n", session.capture
    assert_equal 0, $?.exitstatus
  end

  def test_capture_with_different_ps1_and_ps2
    session.env['PS1'] = '% '
    session.env['PS2'] = ': '
    session.on(/\% /, "echo ab\\\n")
    session.on(/\: /, "c\n")
    session.on(/\% /, "exit\n")

    assert_equal "% echo ab\\\n: c\nabc\n% exit\nexit\n", session.capture
    assert_equal 0, $?.exitstatus
  end
end