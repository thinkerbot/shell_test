require 'pty'

module ShellTest
  module ShellMethods
    module Utils
      module_function

      # Spawns a PTY session and returns the Process::Status for the session
      # upon completion. The PTY process is killed upon an unhandled error
      # (but the error is re-raised for further handling).
      #
      # Note that $? is set by spawn but is not reliable until 1.9.2 (ish).
      # Prior to that PTY used a cleanup thread that would wait on a spawned
      # process and raise a PTY::ChildExited error in some cases.  As a result
      # manual calls to Process.wait (which would set $?) cause a race
      # condition. Rely on the output of spawn instead.
      def spawn(cmd)
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            yield(master, slave)
            Process.wait(pid)

          rescue PTY::ChildExited
            # handle a ChildExited error on 1.8.6 and 1.8.7 as a 'normal' exit
            # route.  1.9.2 does not exit this way.
            return $!.status

          rescue Exception
            # cleanup the pty on error
            Process.kill(9, pid)

            # any wait can cause a ChildExited error so account for that here
            # - the $? is indeterminate in this case prior to 1.9.2
            Process.wait(pid) rescue PTY::ChildExited

            raise
          end
        end

        $?
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
