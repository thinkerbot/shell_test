require File.expand_path('../../test_helper', __FILE__) 
require 'shell_test/regexp_escape'

class RegexpEscapeTest < Test::Unit::TestCase
  RegexpEscape = ShellTest::RegexpEscape

  #
  # documentation test
  #

  def test_documentation
    assert_equal 'reg\[exp\]\+\ chars\.\ are\(quoted\)', RegexpEscape.escape('reg[exp]+ chars. are(quoted)')
    assert_equal 'these\ are\ not:\ a(b*)c',  RegexpEscape.escape('these are not: :.a(b*)c.:')

    assert_equal 'a.*?b(?:(?m).*?)c', RegexpEscape.escape('a:...:b:....:c')
    assert_equal 'a.{1}b', RegexpEscape.escape('a:..{1}.:b') 

    str = %q{
a multiline
:...:
example}
    r = RegexpEscape.new(str)

    assert r =~ %q{
a multiline
matching
example}

    assert r !~ %q{
a failing multiline
example}

    assert_equal str, r.to_s 
  end

  #
  # quote/escape test
  #

  def test_escape_escapes_non_escaped_regexp_characters
    assert_equal 'ab:\.:c', RegexpEscape.escape("ab:.:c")
    assert_equal '\ \+\*\[\(\)\]', RegexpEscape.escape(" +*[()]")
  end

  def test_escape_preserves_escaped_regexp_characters
    assert_equal 'ab.{1}c', RegexpEscape.escape("ab:..{1}.:c")
    assert_equal ' +*[()]', RegexpEscape.escape(":. +*[()].:")
    assert_equal 'abcdef', RegexpEscape.escape("ab:.c.:de:.f.:")
  end

  def test_escape_treats_no_str_as_no_str
    assert_equal "az", RegexpEscape.escape("a:..:z")
  end

  def test_escape_treats_single_period_as_a_single_line_lazy_match_to_any
    assert_equal "a.*?z", RegexpEscape.escape("a:...:z")
  end

  def test_escape_treats_multiple_periods_as_a_multiline_lazy_match_to_any
    assert_equal "a(?:(?m).*?)z", RegexpEscape.escape("a:......:z")
  end

  #
  # matching test
  #

  def test_multiline_regexp_escape
    regexp = RegexpEscape.new(%q{
some \regexp+(text)
:...:
:.\w+.:
more :...: in*[the] m\iddle
another :.\d\d:\d\d.: in the middle
})

    assert regexp =~ %q{
some \regexp+(text)
some arbitrary text
word
more arbitrary text in*[the] m\iddle
another 08:08 in the middle
}

    assert regexp =~ %q{
some \regexp+(text)

word
more  in*[the] m\iddle
another 08:08 in the middle
}

    assert regexp !~ %q{
some \regexp+(text)
some arbitrary text

more arbitrary text in*[the] m\iddle
another 08:08 in the middle
}

    assert regexp !~ %q{
some \regexp+(text)
some arbitrary text
word
more arbitrary text in*[the] m\iddle
another 0808 in the middle
}

  end

  #
  # to_s test
  #

  def test_to_s_returns_original_str
    str = %Q{
some regexp+(text):...:

across  
several \t lines
}
    assert_equal str, RegexpEscape.new(str).to_s
  end
end