module ShellTest
  module StringMethods
    # Asserts whether or not the a and b strings are equal, with a more
    # readable output than assert_equal for large strings (especially large
    # strings with significant whitespace).
    def assert_str_equal(a, b, msg=nil)
      _assert_str_equal outdent(a), b, msg
    end

    def _assert_str_equal(a, b, msg=nil)
      if a == b
        assert true
      else
        flunk %Q{
#{msg}
==================== expected output ====================
#{whitespace_escape(a)}
======================== but was ========================
#{whitespace_escape(b)}
=========================================================
}
      end
    end

    # Asserts whether or not b is like a (which should be a Regexp), and
    # provides a more readable output in the case of a failure as compared
    # with assert_match.
    #
    # If a is a string it is turned into a RegexpEscape.
    def assert_str_match(a, b, msg=nil)
      a = outdent(a) if a.kind_of?(String)
      _assert_str_match a, b, msg
    end

    def _assert_str_match(a, b, msg=nil)
      if a.kind_of?(String)
        a = RegexpEscape.new(a)
      end

      if b =~ a
        assert true
      else
        flunk %Q{
#{msg}
================= expected output like ==================
#{whitespace_escape(a)}
======================== but was ========================
#{whitespace_escape(b)}
=========================================================
}
      end
    end

    # helper for stripping indentation off a string
    def outdent(str)
      str =~ /\A(?:\s*?\n)( *)(.*)\z/m ? $2.gsub!(/^ {0,#{$1.length}}/, '') : str
    end

    # helper for formatting escaping whitespace into readable text
    def whitespace_escape(str)
      str.to_s.gsub(/\s/) do |match|
        case match
        when "\n" then "\\n\n"
        when "\t" then "\\t"
        when "\r" then "\\r"
        when "\f" then "\\f"
        else match
        end
      end
    end
  end
end