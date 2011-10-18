require 'shell_test/regexp_escape'
require 'shell_test/string_methods'
require 'shell_test/shell_methods/session'

module ShellTest
  module ShellMethods
    include StringMethods
    include EnvMethods

    def default_pty_options
      {:max_run_time => 2, :visual => true}
    end

    def pty(script, options={}, &block)
      _pty outdent(script), options, &block
    end

    def _pty(script, options={}, &block)
      options = default_pty_options.merge(options)

      session = Session.new(options)
      session.parse(script, options, &block)
      session.run
    end

    def assert_script(script, options={})
      _assert_script outdent(script), options
    end

    def _assert_script(script, options={})
      pty = _pty(script, options) do |session, expected, actual|
        _assert_str_equal expected, actual do
          session.summary %Q{
%s (%.2fs)
=========================================================
%s
-------------------- expected output --------------------
#{whitespace_escape(expected)}
------------------------ but was ------------------------
#{whitespace_escape(actual)}
=========================================================
}
        end
      end

      if status = options[:exitstatus]
        assert_equal(status, pty.agent_status.exitstatus)
      end
    end

    def assert_script_match(script, options={})
      _assert_script_match outdent(script), options
    end

    def _assert_script_match(script, options={})
      pty = _pty(script, options) do |session, expected, actual|
        _assert_str_match expected, actual do
          session.summary %Q{
%s (%.2fs)
=========================================================
%s
----------------- expected output like ------------------
#{whitespace_escape(expected)}
------------------------ but was ------------------------
#{whitespace_escape(actual)}
=========================================================
}
        end
      end

      if status = options[:exitstatus]
        assert_equal(status, pty.agent_status.exitstatus)
      end
    end
  end
end
