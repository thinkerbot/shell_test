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
  # parse test
  #

  def test_parse_splits_input_into_steps_along_ps1_and_ps2
    session.parse "$ echo ab\\\n> c\nabc\n$ exit\nexit\n"
    assert_equal [
      [session.ps1r, "echo ab\\\n", nil, nil],
      [session.ps2r, "c\n", nil, nil],
      [session.ps1r, "exit\n", -1, nil],
      [nil, nil, nil, nil]
    ], session.steps
  end

  def test_parse_splits_input_at_mustache
    session.parse "$ sudo echo abc\nPassword: {{secret}}\nabc\n$ exit\nexit\n"
    assert_equal [
      [session.ps1r, "sudo echo abc\n", nil, nil],
      [/^Password: \z/, "secret\n", nil, nil],
      [session.ps1r, "exit\n", -1, nil],
      [nil, nil, nil, nil]
    ], session.steps
  end

  def test_parse_allows_specification_of_alternate_inline_regexp
    session.parse "$ sudo echo abc\nPassword: % secret\nabc\n$ exit\nexit\n", /% /
    assert_equal [
      [session.ps1r, "sudo echo abc\n", nil, nil],
      [/^Password: \z/, "secret\n", nil, nil],
      [session.ps1r, "exit\n", -1, nil],
      [nil, nil, nil, nil]
    ], session.steps
  end

  def test_parse_allows_specification_of_a_max_run_time_per_input
    session.parse "$ if true # [1]\n> then echo abc  # [2.2]\n> fi\n$ exit# [0.1]\nexit\n"
    assert_equal [
      [session.ps1r, "if true \n", nil, nil],
      [session.ps2r, "then echo abc  \n", 1, nil],
      [session.ps2r, "fi\n", 2.2, nil],
      [session.ps1r, "exit\n", -1, nil],
      [nil, nil, 0.1, nil]
    ], session.steps
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