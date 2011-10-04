# :stopdoc:
module ShellTest
  module ShellMethods
    module Utils
      module_function

      undef spawn

      def spawn(cmd)
        result, exception = nil, nil
        begin
          PTY.spawn(cmd) do |slave, master, pid|
            begin
              result = yield(master, slave)
            rescue Exception
              Process.kill(9, pid)
              exception = $!
              raise
            ensure
              Process.wait(pid)
            end
          end
        rescue PTY::ChildExited
          system "echo 'exit #{$!.status.exitstatus}' | sh"
          raise exception if exception
        end
        result
      end
    end
  end
end
# :startdoc:
