require 'pty'

module ShellTest
  module ShellMethods
    module Utils
      module_function

      # Spawns a PTY session and returns the Process::Status for the session
      # upon completion. The PTY process is killed upon an unhandled error
      # (but the error is re-raised for further handling).
      def spawn(cmd, log=[])
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            yield(master, slave)
          rescue Exception
            Process.kill(9, pid)
            raise
          ensure
            Process.wait(pid)
          end
        end

        $?
      end
    end
  end
end
