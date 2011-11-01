require 'shell_test/env_methods'
require 'shell_test/regexp_escape'
require 'shell_test/string_methods'
require 'shell_test/shell_methods/session'

module ShellTest
  module ShellMethods
    include StringMethods
    include EnvMethods

    attr_reader :original_env

    def setup
      super
      @original_env = set_env('PS1' => '$ ', 'PS2' => '> ')
    end

    def teardown
      set_env(@original_env)
      super
    end

    def pty(script, options={}, &block)
      _pty outdent(script), options, &block
    end

    def _pty(script, options={}, &block)
      session = Session.new(options)
      session.parse(script, options, &block)
      session.run
    end

    def assert_script(script, options={})
      _assert_script outdent(script), options
    end

    def _assert_script(script, options={})
      pty = _pty(script, options) do |session, expected, actual|
        expected = expand_ctrl_chars(expected)
        actual   = expand_ctrl_chars(actual)

        _assert_str_equal expected, actual do
          session.summary %Q{
%s (elapsed: %.2fs max: %.2fs)
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
        assert_equal(status, pty.status.exitstatus)
      end
    end

    def assert_script_match(script, options={})
      _assert_script_match outdent(script), options
    end

    def _assert_script_match(script, options={})
      pty = _pty(script, options) do |session, expected, actual|
        expected = expand_ctrl_chars(expected)
        actual   = expand_ctrl_chars(actual)

        _assert_str_match expected, actual do
          session.summary %Q{
%s (%.2f:%.2fs)
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
        assert_equal(status, pty.status.exitstatus)
      end
    end
  end
end
