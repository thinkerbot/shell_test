require 'pty'

module ShellTest
  module ShellMethods
    module Utils
      module_function

      # Spawns a PTY session, returns the block result, and sets $?.  The PTY
      # process is killed upon an unhandled error (but the error is re-raised
      # for further handling).
      def spawn(cmd)
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            return yield(master, slave)
          rescue Exception
            Process.kill(9, pid)

            # Clearing the slave allows quicker exits on OS X.
            while IO.select([slave],nil,nil,0.1)
              begin
                break unless slave.read(1)
              rescue Errno::EIO
                # On some linux (ex ubuntu) read can return an eof or fail with
                # an EIO error when a terminal disconnect occurs and an EIO
                # condition occurs - the exact behavior is unspecified but the
                # meaning is the same... no more data is available, so break.
                break
              end
            end

            raise
          ensure
            Process.wait(pid)
          end
        end
      end
    end
  end
end
