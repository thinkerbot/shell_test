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
  # cr test
  #

  def test_cr_removes_carriage_returns_back_to_newline
    assert_equal "xyz", cr("abc\rxyz")
    assert_equal "abc\nxyz\n", cr("abc\nXYZ\rxyz\n")
    assert_equal "", cr("abc\r")
    assert_equal "abc\n", cr("abc\n\r")
  end

  #
  # bs test
  #

  def test_bs_removes_backspace_and_previous_char
    assert_equal "ac", bs("\bac")
    assert_equal "c", bs("a\bc")
    assert_equal "a", bs("ac\b")
  end

  #
  # bell test
  #

  def test_bell_removes_bell_char
    assert_equal "ac", bell("\aac")
    assert_equal "ac", bell("a\ac")
    assert_equal "ac", bell("ac\a")
  end

  #
  # null test
  #

  def test_null_removes_null_char
    assert_equal "ac", null("\0ac")
    assert_equal "ac", null("a\0c")
    assert_equal "ac", null("ac\0")
  end

  #
  # ff test
  #

  def test_ff_adds_ff_chars
    assert_equal "\nac", ff("\fac")
    assert_equal "a\n c", ff("a\fc")
    assert_equal "ac\n  ", ff("ac\f")
  end
end