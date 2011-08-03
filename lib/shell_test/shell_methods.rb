require 'shell_test/regexp_escape'
require 'shell_test/command_parser'
require 'shell_test/string_methods'

module ShellTest
  module ShellMethods
    include StringMethods

    def setup
      super
      @notify_method_name = true
    end

    # Parse a script into an array of [cmd, output, status] triplets.
    def parse_script(script, options={})
      CommandParser.new(options).parse(script)
    end

    # Returns true if the ENV variable 'VERBOSE' is true.  When verbose,
    # ShellTest prints the expanded commands of sh_test to $stdout.
    def verbose?
      verbose = ENV['VERBOSE']
      verbose && verbose =~ /^true$/i ? true : false
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

    def sh(cmd)
      if @notify_method_name && verbose?
        @notify_method_name = false
        puts
        puts method_name 
      end

      start  = Time.now
      result = `#{cmd}`
      finish = Time.now

      if verbose?
        elapsed = "%.3f" % [finish-start]
        puts "  (#{elapsed}s) #{cmd}"
      end

      result
    end

    def assert_script(script, options={})
      _assert_script outdent(script), options
    end

    def _assert_script(script, options={})
      parse_script(script, options).each do |cmd, output, status|
        result = sh(cmd)

        _assert_str_equal(output, result, cmd) if output
        assert_equal(status, $?.exitstatus, cmd)  if status
      end
    end

    def assert_script_match(script, options={})
      _assert_script_match outdent(script), options
    end

    def _assert_script_match(script, options={})
      parse_script(script, options).each do |cmd, output, status|
        result = sh(cmd)

        _assert_str_match(output, result, cmd)       if output
        assert_equal(status, $?.exitstatus, cmd) if status
      end
    end
  end
end
