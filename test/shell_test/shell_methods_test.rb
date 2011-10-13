require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/shell_methods'

class ShellMethodsTest < Test::Unit::TestCase
  include ShellTest::ShellMethods

  #
  # pty test
  #

  def test_pty_captures_agent_errors_with_session_status
    err = assert_raises(Agent::UnsatisfiedError) do
      pty "$ echo 'abc'; sleep 1\n", :max_run_time => 0.1
    end
    assert_str_match %q{
      timeout waiting for /\$\ /

      /bin/sh (0.:...:s)
      =========================================================
      $ echo 'abc'; sleep 1
      abc
      
      =========================================================
    }, err.message
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

  def test_assert_script_with_null
    assert_script %q{
      $ printf "abc\0xyz\n"
      abcxyz
    }
  end

  def test_assert_script_with_bell
    assert_script %q{
      $ printf "abc\axyz\n"
      abcxyz
    }
  end

  def test_assert_script_with_backspace
    assert_script %q{
      $ printf "abc\bx\byz\n"
      abyz
    }
  end

  def test_assert_script_with_horizontal_tab
    assert_script %q{
      $ printf "abc\txyz\n"
      abc	xyz
    }
  end

  def test_assert_script_with_line_feed
    assert_script %q{
      $ printf "abc\nxyz\n"
      abc
      xyz
    }
  end

  def test_assert_script_with_form_feed
    assert_script %q{
      $ printf "abc\fxyz\n"
      abc
         xyz
    }
  end

  def test_assert_script_with_carriage_return
    assert_script %q{
      $ printf "abc\rxyz\n"
      xyz
    }
  end
  def test_exit_status
    assert_script %{
      $ false
    }, :exitstatus => 1
  end
  def test_assert_script_for_example_cut_from_terminal
    parent_dir = __FILE__.chomp('.rb')
    dir = File.join(parent_dir, __name__)

    begin
      FileUtils.mkdir_p(dir)
      Dir.chdir(dir) do
        assert_script %q{
          $ for n in one two; do
          > echo $n
          > done
          one
          two
          $ printf "abcdefgh"
          abcdefgh$ printf "xyz\n"
          xyz
          $ cat > file <<DOC
          > abc
          > xyz
          > pqr
          > DOC
          $ cat file file file file file file file file file | tr "\n" '.'
          abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.abc.xyz.pqr.$ 
          $ 
          $ rm file
          $ exit
          exit
        }, :noexit => true
      end
    ensure
      FileUtils.rm_r(parent_dir)
    end
  end

  def test_assert_script_fails_on_mismatch
    assert_raises(TestUnitErrorClass) { assert_script %Q{$ printf ""\nflunk} }
    assert_raises(TestUnitErrorClass) { assert_script %Q{$ echo pass\nflunk} }
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