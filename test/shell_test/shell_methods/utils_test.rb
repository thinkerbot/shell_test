require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/utils"

class UtilsTest < Test::Unit::TestCase
  include ShellTest::ShellMethods::Utils

  #
  # spawn test
  #

  def test_spawn_sets_exit_status
    spawn('/bin/sh') do |master, slave|
      master.write "exit 8\n"
    end
    assert_equal 8, $?.exitstatus
  end

  def test_spawn_returns_block_output
    result = spawn('/bin/sh') do |master, slave|
      master.close
      slave.close
      :result 
    end
    assert_equal :result, result
  end

  #
  # trim test
  #

  def test_trim_documentation
    assert_equal "abc\n", trim("abc\n$ ", /\$\ /)
  end

  def test_trim_trims_a_string_at_the_last_match_of_regexp
    assert_equal "abc", trim("abcxyz", /\w{3}/)
    assert_equal "abc", trim("abc", /xyz/)
  end

  #
  # reformat test
  #

  def test_reformat_documentation
    assert_equal "abc",     reformat("ab\0c")
    assert_equal "abc",     reformat("ab\ac")
    assert_equal "ac",      reformat("ab\bc")
    assert_equal "ab\tc",   reformat("ab\tc")
    assert_equal "ab\nc",   reformat("ab\nc")
    assert_equal "ab\n  c", reformat("ab\fc")
    assert_equal "c",       reformat("ab\rc")
  end

  def test_reformat_removes_null_char
    assert_equal "ac", reformat("\0ac")
    assert_equal "ac", reformat("a\0c")
    assert_equal "ac", reformat("ac\0")
  end

  def test_reformat_removes_bell_char
    assert_equal "ac", reformat("\aac")
    assert_equal "ac", reformat("a\ac")
    assert_equal "ac", reformat("ac\a")
  end

  def test_reformat_removes_backspace_and_previous_char
    assert_equal "ac", reformat("\bac")
    assert_equal "c",  reformat("a\bc")
    assert_equal "a",  reformat("ac\b")
  end

  def test_reformat_preserves_tab
    assert_equal "\tac", reformat("\tac")
    assert_equal "a\tc", reformat("a\tc")
    assert_equal "ac\t", reformat("ac\t")
  end

  def test_reformat_preserves_newline
    assert_equal "\nac", reformat("\nac")
    assert_equal "a\nc", reformat("a\nc")
    assert_equal "ac\n", reformat("ac\n")
  end

  def test_reformat_adds_ff_chars
    assert_equal "\nac",   reformat("\fac")
    assert_equal "a\n c",  reformat("a\fc")
    assert_equal "ac\n  ", reformat("ac\f")
  end

  def test_reformat_removes_carriage_returns_back_to_newline
    assert_equal "ac", reformat("\rac")
    assert_equal "c",  reformat("a\rc")
    assert_equal "",   reformat("ac\r")

    assert_equal "ab\nxy", reformat("ab\n\rxy")
    assert_equal "ab\ny",  reformat("ab\nx\ry")
    assert_equal "ab\n",   reformat("ab\nxy\r")
  end
end