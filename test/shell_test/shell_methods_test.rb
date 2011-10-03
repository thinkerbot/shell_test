require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/shell_methods'

class ShellMethodsTest < Test::Unit::TestCase
  include ShellTest::ShellMethods

  #
  # pty test
  #

  def test_pty_allows_specification_of_max_run_time
    err = assert_raises(Agent::UnsatisfiedError) do
      pty "$ sleep 1\n", :max_run_time => 0.1
    end
    assert_equal 'timeout waiting for /\$\ /', err.message
  end

  #
  # assert_script test
  #

  def test_assert_script_correctly_matches_no_output
    assert_script %{
      $ printf ''
    }
  end

  def test_assert_script_correctly_matches_whitespace_output
    assert_script %{
      $ printf "\\t\\n  "
      \t
        }
  end

  def test_assert_script_strips_indents
    assert_script %Q{
    $ echo goodnight
    goodnight
    }

    assert_script %Q{ \t   \r
    $ echo goodnight
    goodnight
    }

    assert_script %Q{
    $ printf "\\t\\n  "
    \t
      }

    assert_script %Q{
    $ echo

    }

    assert_script %Q{$ echo

}
  end

  def test_assert_script_for_multiple_commands
    assert_script %{
      $ echo one
      one
      $ echo two
      two
    }
  end

  def test_assert_script_for_multiline_commands
    assert_script %{
      $ for n in one two; do
      >   echo $n
      > done
      one
      two
    }
  end

  def test_assert_script_for_multiple_commands_with_context
    assert_script %{
      $ VALUE=one
      $ echo $VALUE
      one
    }
  end

  def test_assert_script_for_long_commands_and_output
    str = "abcdefgh" * 20
    assert_script %{
      $ echo #{str}
      #{str}
    }
  end

  def test_assert_script_fails_on_mismatch
    assert_raises(TestUnitErrorClass) { assert_script %Q{printf ""\nflunk} }
    assert_raises(TestUnitErrorClass) { assert_script %Q{echo pass\nflunk} }
  end

  #
  # _assert_script test
  #

  def test__assert_script_does_not_strip_indents
    _assert_script %Q{
    $ printf "    \\t\\n      "
    \t
      }
  end

  #
  # assert_script_match test
  #

  def test_assert_script_match_matches_regexps_to_output
    assert_script_match %Q{
      $ echo "goodnight
      > moon"
      goodnight
      m:.o+.:n
    }
  end

  def test_assert_script_match_fails_on_mismatch
    assert_raises(TestUnitErrorClass) do
      assert_script_match %Q{
        $ echo 'hello world'
        goodnight m:.o+.:n
      }
    end
  end

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

  #
  # assert_str_match test
  #

  def test_assert_str_match
    assert_str_match(/abc/, "...abc...")
  end

  def test_assert_str_match_regexp_escapes_strings
    assert_str_match "a:...:c", "...alot of random stuff toc..."
  end
end