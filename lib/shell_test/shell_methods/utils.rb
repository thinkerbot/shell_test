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
      def spawn(cmd, log=[])
        # The race condition described above actually applies to both kill and
        # wait which raise Errno::ESRCH or Errno::ECHILD if they lose the
        # race.  This code is designed to capture those errors if they occur
        # and then give the cleanup thread a chance to take over; eventually
        # it will raise a ChildExited error.  This is a sketchy use of
        # exceptions for flow control but there is little option - a
        # consequence of PTY using threads with side effects.
        PTY.spawn(cmd) do |slave, master, pid|
          begin
            yield(master, slave)

            begin
              Process.wait(pid)
            rescue Errno::ECHILD
              Thread.pass
              raise
            end

          rescue PTY::ChildExited
            # This is the 'normal' exit route on 1.8.6 and 1.8.7.
            return $!.status

          rescue Exception => error
            begin

              # Manually cleanup the pid on error.  This code no longer cares
              # what exactly happens to $? - the point is to make sure the
              # child doesn't become a zombie and then re-raise the error.
              begin
                Process.kill(9, pid)
              rescue Errno::ESRCH
                Thread.pass
                raise
              end

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

              begin
                Process.wait(pid)
              rescue Errno::ECHILD
                Thread.pass
                raise
              end

            rescue PTY::ChildExited
              # The cleanup thread could finish at any point in the rescue
              # handling so account for that here.
            ensure
              raise error
            end
          end
        end

        $?
      end

    end
  end
end
