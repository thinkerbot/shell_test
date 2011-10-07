require 'pty'

module ShellTest
  module ShellMethods
    module Utils
      module_function

      # Spawns a PTY session and ensures $? is set correctly upon completion.
      # The PTY process is killed upon an unhandled error (but the error is
      # re-raised for further handling).  Returns the result of the block.
      def spawn(cmd)
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            return yield(master, slave)
          rescue Exception
            Process.kill(9, pid)
            raise
          ensure
            Process.wait(pid)
          end
        end
      end

      # Reformats control characters in str to their printable equivalents.
      # Specifically:
      #
      #   ctrl char         before    after
      #   null              "ab\0c"    "abc"
      #   bell              "ab\ac"    "abc"
      #   backspace         "ab\bc"    "ac"
      #   horizonal tab     "ab\tc"    "ab\tc"
      #   line feed         "ab\nc"    "ab\nc"
      #   form feed         "ab\fc"    "ab\n  c"
      #   carraige return   "ab\rc"    "c"
      #
      # Also trims a string at the last match of regexp, if given.
      #
      #   reformat("abc\n$ ", /\$\ /)  # => "abc\n"
      #
      def reformat(str, regexp=nil)
        tail = regexp ? str.scan(regexp).last : nil
        str  = str.chomp tail
        str.gsub!(/^.*?\r/, '')
        str.gsub!(/(\A#{"\b"}|.#{"\b"}|#{"\a"}|#{"\0"})/m, '')
        str.gsub!(/(^.*?)\f/) {|match| "#{$1}\n#{' ' * $1.length}" }
        str
      end
    end
  end
end

if RUBY_VERSION =~ /^1\.8\./
  require 'shell_test/shell_methods/shim'
end