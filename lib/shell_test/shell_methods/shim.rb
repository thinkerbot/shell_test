# :stopdoc:
module ShellTest
  module ShellMethods
    module Utils
      module_function

      undef spawn

      def spawn(cmd)
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            yield(master, slave)
            Process.wait(pid)

          rescue PTY::ChildExited
            # 1.8.6 and 1.8.7 often will exit this way.
            # 1.9.2 does not exit this way.
            return $!.status

          rescue Exception
            # Cleanup the pty on error (specifically the EOF timeout)
            Process.kill(9, pid)
            Process.wait(pid)
          end
        end

        $?
      end
    end
  end
end
# :startdoc:
