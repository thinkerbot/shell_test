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
  # parse test
  #

  def test_parse_splits_input_into_steps_along_ps1_and_ps2
    session.parse "$ echo ab\\\n> c\nabc\n$ exit\nexit\n"
    assert_equal [
      [session.ps1r, "echo ab\\\n"],
      [session.ps2r, "c\n"],
      [session.ps1r, "exit\n"]
    ], session.steps.map {|step| step[0,2] }
  end

  def test_parse_splits_input_at_mustache
    session.parse "$ sudo echo abc\nPassword: {{secret}}\nabc\n$ exit\nexit\n"
    assert_equal [
      [session.ps1r, "sudo echo abc\n"],
      [/^Password: \z/, "secret\n"],
      [session.ps1r, "exit\n"]
    ], session.steps.map {|step| step[0,2] }
  end

  def test_parse_allows_specification_of_alternate_inline_regexp
    session.parse "$ sudo echo abc\nPassword: % secret\nabc\n$ exit\nexit\n", /% /
    assert_equal [
      [session.ps1r, "sudo echo abc\n"],
      [/^Password: \z/, "secret\n"],
      [session.ps1r, "exit\n"]
    ], session.steps.map {|step| step[0,2] }
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