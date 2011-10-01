require 'shell_test/regexp_escape'
require 'shell_test/string_methods'
require 'shell_test/shell_methods/session'

module ShellTest
  module ShellMethods
    include StringMethods

    def setup
      super
      @notify_method_name = true
    end

    # Returns true if the ENV variable 'VERBOSE' is true.  When verbose,
    # ShellTest prints the expanded commands of sh_test to $stdout.
    def verbose?
      verbose = ENV['VERBOSE']
      verbose && verbose =~ /^true$/i ? true : false
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
      Session.run("/bin/sh", script, options) do |expected, actual, cmd|
        _assert_str_equal expected, actual, cmd
      end
      if status = options[:status]
        assert_equal(status, $?.exitstatus)
      end
    end

    def assert_script_match(script, options={})
      _assert_script_match outdent(script), options
    end

    def _assert_script_match(script, options={})
      Session.run("/bin/sh", script, options) do |expected, actual, cmd|
        _assert_script_match expected, actual, cmd
      end
      if status = options[:status]
        assert_equal(status, $?.exitstatus)
      end
    end
  end
end
