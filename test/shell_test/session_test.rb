require File.expand_path("../../test_helper", __FILE__)
require "shell_test/session"

class SessionTest < Test::Unit::TestCase
  Session = ShellTest::Session

  attr_accessor :session

  def setup
    super
    @session = Session.new "/bin/sh"
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

  #
  # run test
  #

  def test_run_with_non_interactive_command
    session = Session.new "echo hello world"
    buffer = ""
    session.run {|str| buffer << str }

    assert_equal "hello world\r\n", buffer
    assert_equal 0, $?.exitstatus
  end

  def test_run_captures_exit_status_of_non_interactive_command
    session = Session.new %{ruby -e "puts 'hello world'; exit 8"}
    buffer = ""
    session.run {|str| buffer << str }

    assert_equal "hello world\r\n", buffer
    assert_equal 8, $?.exitstatus
  end

  def test_run_with_non_interactive_shell
    session.on(/^\$ /, "echo abc\n")
    session.on(/^\$ /, "exit 8\n")
    buffer = ""

    with_env("PS1" => "$ ", "PS2" => "> ") do
      session.run {|str| buffer << str }
    end

    assert_equal "$ echo abc\r\nabc\r\n$ exit 8\r\nexit\r\n", buffer
    assert_equal 8, $?.exitstatus
  end
end