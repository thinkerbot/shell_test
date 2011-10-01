require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/parser"

class ParserTest < Test::Unit::TestCase
  Parser = ShellTest::ShellMethods::Parser

  attr_accessor :parser

  def setup
    super
    @parser = Parser.new
  end

  #
  # parse test
  #

  def test_parse_splits_input_into_steps_along_ps1_and_ps2
    steps = parser.parse "$ echo ab\\\n> c\nabc\n$ exit\nexit\n"
    assert_equal [
      ["$ ", "echo ab\\\n", parser.ps1r, nil],
      ["> ", "c\n", parser.ps2r, nil],
      ["abc\n$ ", "exit\n", parser.ps1r, -1],
      ["exit\n", nil, nil, nil]
    ], steps
  end

  def test_parse_splits_input_at_mustache
    steps = parser.parse "$ sudo echo abc\nPassword: {{secret}}\nabc\n$ exit\nexit\n"
    assert_equal [
      ["$ ", "sudo echo abc\n", parser.ps1r, nil],
      ["Password: ", "secret\n", /^Password: \z/, nil],
      ["abc\n$ ", "exit\n", parser.ps1r, -1],
      ["exit\n", nil, nil, nil]
    ], steps
  end

  def test_parse_allows_specification_of_a_max_run_time_per_input
    steps = parser.parse "$ if true # [1]\n> then echo abc  # [2.2]\n> fi\nabc\n$ exit# [0.1]\nexit\n"
    assert_equal [
      ["$ ", "if true \n", parser.ps1r, nil],
      ["> ", "then echo abc  \n",  parser.ps2r, 1],
      ["> ", "fi\n",  parser.ps2r, 2.2],
      ["abc\n$ ", "exit\n", parser.ps1r, -1],
      ["exit\n", nil, nil, 0.1]
    ], steps
  end
end