require 'pty'

module ShellTest
  module Pty
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

      # Sets the specified ENV variables and returns the *current* env.
      # If replace is true, current ENV variables are replaced; otherwise
      # the new env variables are simply added to the existing set.
      def set_env(env={}, replace=false)
        current_env = {}
        ENV.each_pair do |key, value|
          current_env[key] = value
        end

        ENV.clear if replace

        env.each_pair do |key, value|
          if value.nil?
            ENV.delete(key)
          else
            ENV[key] = value
          end
        end if env

        current_env
      end

      # Sets the specified ENV variables for the duration of the block.
      # If replace is true, current ENV variables are replaced; otherwise
      # the new env variables are simply added to the existing set.
      #
      # Returns the block return.
      def with_env(env={}, replace=false)
        current_env = nil
        begin
          current_env = set_env(env, replace)
          yield
        ensure
          if current_env
            set_env(current_env, true)
          end
        end
      end
    end
  end
end