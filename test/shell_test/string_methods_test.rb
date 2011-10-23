require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/string_methods'

class StringMethodsTest < Test::Unit::TestCase
  include ShellTest::StringMethods

  #
  # assert_str_equal test
  #

  def test_assert_str_equal
    assert_str_equal %{
    line one
      line two
    }, "line one\n  line two\n"

    assert_str_equal %{
    line one
      line two}, "line one\n  line two"

    assert_str_equal %{  \t   \r
    line one
    line two
    }, "line one\nline two\n"

    assert_str_equal %{
    
    
    }, "\n\n"

    assert_str_equal %{
    
    }, "\n"

    assert_str_equal %{  \t   \r
    
    }, "\n"

    assert_str_equal %{
    }, ""

    assert_str_equal %q{}, ""
    assert_str_equal %q{line one
line two
}, "line one\nline two\n"
  end

  def test_assert_str_equal_yields_to_block_for_message_if_given
    err = assert_raises(TestUnitErrorClass) do
      assert_str_equal 'a', 'b' do |a,b|
        "#{a}..#{b}"
      end
    end

    # code this defensively such that a terminal period is allowed
    # by Test::Unit flunk (MiniTest adds no such period)
    assert_equal "a..b", err.message.chomp('.')
  end

  #
  # assert_str_match test
  #

  def test_assert_str_match
    assert_str_match(/abc/, "...abc...")
  end

  def test_assert_str_match_regexp_escapes_strings
    assert_str_match "a:...:c", "...alot of random stuff toc..."
  end

  def test_assert_str_match_yields_to_block_for_message_if_given
    err = assert_raises(TestUnitErrorClass) do
      assert_str_match(/a/, 'b') do |a,b|
        "#{a}..#{b}"
      end
    end

    # code this defensively such that a terminal period is allowed
    # by Test::Unit flunk (MiniTest adds no such period)
    assert_equal "(?-mix:a)..b", err.message.chomp('.')
  end

  #
  # expand_ctrl_chars test
  #

  def test_expand_ctrl_chars_documentation
    assert_equal "abc",     expand_ctrl_chars("ab\0c")
    assert_equal "abc",     expand_ctrl_chars("ab\ac")
    assert_equal "ac",      expand_ctrl_chars("ab\bc")
    assert_equal "ab\tc",   expand_ctrl_chars("ab\tc")
    assert_equal "ab\nc",   expand_ctrl_chars("ab\nc")
    assert_equal "ab\n  c", expand_ctrl_chars("ab\fc")
    assert_equal "c",       expand_ctrl_chars("ab\rc")
  end

  def test_expand_ctrl_chars_removes_null_char
    assert_equal "ac", expand_ctrl_chars("\0ac")
    assert_equal "ac", expand_ctrl_chars("a\0c")
    assert_equal "ac", expand_ctrl_chars("ac\0")
  end

  def test_expand_ctrl_chars_removes_bell_char
    assert_equal "ac", expand_ctrl_chars("\aac")
    assert_equal "ac", expand_ctrl_chars("a\ac")
    assert_equal "ac", expand_ctrl_chars("ac\a")
  end

  def test_expand_ctrl_chars_removes_backspace_and_previous_char
    assert_equal "ac", expand_ctrl_chars("\bac")
    assert_equal "c",  expand_ctrl_chars("a\bc")
    assert_equal "a",  expand_ctrl_chars("ac\b")
  end

  def test_expand_ctrl_chars_preserves_tab
    assert_equal "\tac", expand_ctrl_chars("\tac")
    assert_equal "a\tc", expand_ctrl_chars("a\tc")
    assert_equal "ac\t", expand_ctrl_chars("ac\t")
  end

  def test_expand_ctrl_chars_preserves_newline
    assert_equal "\nac", expand_ctrl_chars("\nac")
    assert_equal "a\nc", expand_ctrl_chars("a\nc")
    assert_equal "ac\n", expand_ctrl_chars("ac\n")
  end

  def test_expand_ctrl_chars_adds_ff_chars
    assert_equal "\nac",   expand_ctrl_chars("\fac")
    assert_equal "a\n c",  expand_ctrl_chars("a\fc")
    assert_equal "ac\n  ", expand_ctrl_chars("ac\f")
  end

  def test_expand_ctrl_chars_removes_carriage_returns_back_to_newline
    assert_equal "ac", expand_ctrl_chars("\rac")
    assert_equal "c",  expand_ctrl_chars("a\rc")
    assert_equal "",   expand_ctrl_chars("ac\r")

    assert_equal "ab\nxy", expand_ctrl_chars("ab\n\rxy")
    assert_equal "ab\ny",  expand_ctrl_chars("ab\nx\ry")
    assert_equal "ab\n",   expand_ctrl_chars("ab\nxy\r")
  end
end