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
  # split test
  #

  def test_split_splits_input_into_steps_along_ps1_and_ps2
    steps = session.split "$ echo ab\\\n> c\nabc\n$ exit\nexit\n"
    assert_equal [
      ["$ ", "echo ab\\\n", /\$\ /, nil],
      ["> ", "c\n", />\ /, nil],
      ["abc\n$ ", "exit\n", /\$\ /, -1],
      ["exit\n", nil, nil, nil]
    ], steps
  end

  def test_split_adds_exit_if_missing
    steps = session.split "$ echo ab\\\n> c\nabc\n"
    assert_equal [
      ["$ ", "echo ab\\\n", /\$\ /, nil],
      ["> ", "c\n", />\ /, nil],
      ["abc\n$ ", "exit $?\n", /\$\ /, -1],
      ["exit\n", nil, nil, nil]
    ], steps
  end

  def test_split_splits_input_at_mustache
    steps = session.split "$ sudo echo abc\nPassword: {{secret}}\nabc\n$ exit\nexit\n"
    assert_equal [
      ["$ ", "sudo echo abc\n", /\$\ /, nil],
      ["Password: ", "secret\n", /^Password: \z/, nil],
      ["abc\n$ ", "exit\n", /\$\ /, -1],
      ["exit\n", nil, nil, nil]
    ], steps
  end

  def test_split_allows_specification_of_a_max_run_time_per_input
    steps = session.split "$ if true # [1]\n> then echo abc  # [2.2]\n> fi\nabc\n$ exit# [0.1]\nexit\n"
    assert_equal [
      ["$ ", "if true \n", /\$\ /, nil],
      ["> ", "then echo abc  \n",  />\ /, 1],
      ["> ", "fi\n",  />\ /, 2.2],
      ["abc\n$ ", "exit\n", /\$\ /, -1],
      ["exit\n", nil, nil, 0.1]
    ], steps
  end

  #
  # run test
  #

  def test_run_captures_output_into_result_and_sets_exit_status
    session.on(/\$\ /, "echo hello world\n")
    session.on(/\$\ /, "exit 8\n")

    assert_equal "$ echo hello world\nhello world\n$ exit 8\nexit\n", session.run.result
    assert_equal 8, $?.exitstatus
  end

  def test_run_for_multiline_commands
    session.on(/\$\ /, "echo ab\\\n")
    session.on(/>\ /, "c\n")
    session.on(/\$\ /, "exit\n")

    assert_equal "$ echo ab\\\n> c\nabc\n$ exit\nexit\n", session.run.result
    assert_equal 0, $?.exitstatus
  end

  def test_run_with_different_ps1_and_ps2
    session = Session.new(:ps1 => '% ', :ps2 => ': ')
    session.on(/\% /, "echo ab\\\n")
    session.on(/\: /, "c\n")
    session.on(/\% /, "exit\n")

    assert_equal "% echo ab\\\n: c\nabc\n% exit\nexit\n", session.run.result
    assert_equal 0, $?.exitstatus
  end
end