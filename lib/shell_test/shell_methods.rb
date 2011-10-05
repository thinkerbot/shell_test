require 'shell_test/regexp_escape'
require 'shell_test/string_methods'
require 'shell_test/shell_methods/session'

module ShellTest
  module ShellMethods
    include StringMethods
    include EnvMethods

    def default_pty_options
      {:stty => 'raw', :max_run_time => 1, :trim => true}
    end

    def pty(script, options={}, &block)
      _pty outdent(script), options, &block
    end

    def _pty(script, options={}, &block)
      options = default_pty_options.merge(options)
      result = []

      session = Session.new(options)
      session.parse(script, options, &block)

      begin
        session.run(options) do |output, cmd|
          result << output
          result << cmd
        end
      rescue Exception
        raise $!, format_pty_exception($!.message, session, result.join)
      end
      result
    end

    def format_pty_exception(message, session, result)
      args = [session.shell, session.timer.elapsed_time, result, message]

      if message =~ /---.*---/
%Q{
%s (%.2fs)
=========================================================
%s
%s
=========================================================
}
      else
%Q{
%s (%.2fs)
=========================================================
%s
=========================================================
%s
}
      end  % args
    end

    def assert_script(script, options={})
      _assert_script outdent(script), options
    end

    def _assert_script(script, options={})
      _pty(script, options) do |expected, actual, cmd|
        _assert_str_equal expected, actual do
%Q{-------------------- expected output --------------------
#{whitespace_escape(expected)}
------------------------ but was ------------------------
#{whitespace_escape(actual)}}
        end
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
        _assert_str_match expected, actual do
%Q{----------------- expected output like ------------------
#{whitespace_escape(expected)}
------------------------ but was ------------------------
#{whitespace_escape(actual)}}
        end
      end

      if status = options[:exitstatus]
        assert_equal(status, $?.exitstatus)
      end
    end
  end
end
