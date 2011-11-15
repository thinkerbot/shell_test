require 'pty'

module ShellTest
  module ShellMethods
    module Utils
      module_function

      # Spawns a PTY session, returns the block result, and sets $?.  The PTY
      # process is killed upon an unhandled error (but the error is re-raised
      # for further handling).
      def spawn(cmd, log=[])
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
    end
  end
end
