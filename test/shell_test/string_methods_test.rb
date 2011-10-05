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

    assert_equal "a..b", err.message
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

    assert_equal "(?-mix:a)..b", err.message
  end
end