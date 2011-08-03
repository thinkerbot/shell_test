require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/string_methods'

class StringMethodsTest < Test::Unit::TestCase
  include ShellTest::StringMethods

  #
  # assert_output_equal test
  #

  def test_assert_output_equal
    assert_output_equal %{
    line one
      line two
    }, "line one\n  line two\n"

    assert_output_equal %{
    line one
      line two}, "line one\n  line two"

    assert_output_equal %{  \t   \r
    line one
    line two
    }, "line one\nline two\n"

    assert_output_equal %{
    
    
    }, "\n\n"

    assert_output_equal %{
    
    }, "\n"

    assert_output_equal %{  \t   \r
    
    }, "\n"

    assert_output_equal %{
    }, ""

    assert_output_equal %q{}, ""
    assert_output_equal %q{line one
line two
}, "line one\nline two\n"
  end

  #
  # assert_alike test
  #

  def test_assert_alike
    assert_alike(/abc/, "...abc...")
  end

  def test_assert_alike_regexp_escapes_strings
    assert_alike "a:...:c", "...alot of random stuff toc..."
  end
end