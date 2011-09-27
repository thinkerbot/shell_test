require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/pty/session"

class SessionTest < Test::Unit::TestCase
  Session = ShellTest::Pty::Session

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

    assert_equal "$ echo hello world\r\nhello world\r\n$ exit 8\r\nexit\r\n", session.capture
    assert_equal 8, $?.exitstatus
  end

  def test_capture_for_multiline_commands
    session.on(/\$ /, "echo ab\\\n")
    session.on(/\> /, "c\n")
    session.on(/\$ /, "exit\n")

    assert_equal "$ echo ab\\\r\n> c\r\nabc\r\n$ exit\r\nexit\r\n", session.capture
    assert_equal 0, $?.exitstatus
  end
end