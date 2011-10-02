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
    end
  end
end