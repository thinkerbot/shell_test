require 'shell_test/regexp_escape'
require 'shell_test/string_methods'
require 'shell_test/shell_methods/session'

module ShellTest
  module ShellMethods
    include StringMethods
    include EnvMethods

    def default_pty_options
      {:stty => 'raw', :max_run_time => 1}
    end

    def pty(script, options={}, &block)
      _pty outdent(script), options, &block
    end

    def _pty(script, options={}, &block)
      options = default_pty_options.merge(options)

      session = Session.new(options)
      session.parse(script, &block)

      result = []
      current_cmd = nil
      begin
        session.run(options) do |output, cmd|
          result << output
          current_cmd = cmd
        end
        result.join
      rescue
        $!.message << "\n#{result.join}#{current_cmd}"
        raise
      end
    end

    def assert_script(script, options={})
      _assert_script outdent(script), options
    end

    def _assert_script(script, options={})
      _pty(script, options) do |expected, actual, cmd|
        _assert_str_equal expected, actual, cmd
      end

      if status = options[:exitstatus]
        assert_equal(status, $?.exitstatus)
      end
    end

    def assert_script_match(script, options={})
      _assert_script_match outdent(script), options
    end

    def _assert_script_match(script, options={})
      _pty(script, options) do |expected, actual, cmd|
        _assert_str_match expected, actual, cmd
      end

      if status = options[:exitstatus]
        assert_equal(status, $?.exitstatus)
      end
    end
  end
end
