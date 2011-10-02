module ShellTest
  # RegexpEscape is a subclass of regexp that escapes all but the text in a
  # special escape sequence.  This allows the creation of complex regexps to
  # match, for instance, console output.
  #
  # The RegexpEscape.escape (or equivalently the quote) method does the work;
  # all regexp-active characters are escaped except for characters enclosed by
  # ':.' and '.:' delimiters.
  #
  #   RegexpEscape.escape('reg[exp]+ chars. are(quoted)')       # => 'reg\[exp\]\+\ chars\.\ are\(quoted\)'
  #   RegexpEscape.escape('these are not: :.a(b*)c.:')          # => 'these\ are\ not:\ a(b*)c'
  #
  # All-period regexps are treated specially.  A single period is translated
  # to '.*?' to lazily match anything on a single line.  Multiple periods are
  # translated to '(?:(?m).*?)' to lazily match anything actoss multiple
  # lines. Use the '.{n}' notation to specify n arbitrary characters.
  #
  #   RegexpEscape.escape('a:...:b:....:c')        # => 'a.*?b(?:(?m).*?)c'
  #   RegexpEscape.escape('a:..{1}.:b')            # => 'a.{1}b'
  #
  # RegexpEscape instances are initialized using the escaped input string and
  # return the original string upon to_s.
  #
  #   str = %q{
  #   a multiline
  #   :...:
  #   example}
  #   r = RegexpEscape.new(str)
  #
  #   r =~ %q{
  #   a multiline
  #   matching
  #   example}  # => true
  #
  #   r !~ %q{
  #   a failing multiline
  #   example}  # => true
  #
  #   r.to_s    # => str
  #
  class RegexpEscape < Regexp

    # matches the escape sequence
    ESCAPE_SEQUENCE = /:\..*?\.:/

    class << self

      # Escapes regexp-active characters in str, except for character
      # delimited by ':.' and '.:'.  See the class description for
      # details.
      def escape(str)
        substituents = []
        str.scan(ESCAPE_SEQUENCE) do
          regexp_str = $&[2...-2]
          substituents << case regexp_str
          when '.'
            ".*?"
          when /\A\.+\z/
            "(?:(?m).*?)"
          else
            regexp_str
          end
        end
        substituents << ""

        splits = str.split(ESCAPE_SEQUENCE).collect do |split|
          super(split)
        end
        splits << "" if splits.empty?

        splits.zip(substituents).to_a.flatten.join
      end

      # Same as escape.
      def quote(str)
        escape(str)
      end
    end

    # Generates a new RegexpEscape by escaping the str, using the same
    # options as Regexp.
    def initialize(str, *options)
      super(RegexpEscape.escape(str), *options)
      @original_str = str
    end

    # Returns the original string for self
    def to_s
      @original_str
    end
  end
end