require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/utils"

class UtilsTest < Test::Unit::TestCase
  include ShellTest::ShellMethods::Utils

  #
  # spawn test
  #

  def test_spawn_sets_exit_status
    spawn('/bin/sh') do |master, slave|
      master.write "exit 8\n"
    end
    assert_equal 8, $?.exitstatus
  end

  def test_spawn_returns_block_output
    result = spawn('/bin/sh') do |master, slave|
      master.close
      slave.close
      :result 
    end
    assert_equal :result, result
  end

  #
  # set_env test
  #

  def test_set_env_sets_the_env_and_returns_the_current_env
    current_env = {}
    begin
      ENV.each_pair do |key, value|
        current_env[key] = value
      end

      assert_equal nil, ENV['NEW_ENV_VAR']
      assert_equal nil, current_env['NEW_ENV_VAR']

      assert_equal current_env, set_env('NEW_ENV_VAR' => 'value')
      assert_equal 'value', ENV['NEW_ENV_VAR']
    ensure
      ENV.clear
      current_env.each_pair do |key, value|
        ENV[key] = value
      end
    end
  end

  #
  # with_env test
  #

  def test_with_env_sets_variables_for_duration_of_block
    assert_equal nil, ENV['UNSET_VARIABLE']
    ENV['SET_VARIABLE'] = 'set'

    was_in_block = false
    with_env 'UNSET_VARIABLE' => 'unset' do
      was_in_block = true
      assert_equal 'set', ENV['SET_VARIABLE']
      assert_equal 'unset', ENV['UNSET_VARIABLE']
    end

    assert_equal true, was_in_block
    assert_equal 'set', ENV['SET_VARIABLE']
    assert_equal nil, ENV['UNSET_VARIABLE']
    assert_equal false, ENV.has_key?('UNSET_VARIABLE')
  end

  def test_with_env_resets_variables_even_on_error
    assert_equal nil, ENV['UNSET_VARIABLE']

    was_in_block = false
    err = assert_raises(RuntimeError) do
      with_env 'UNSET_VARIABLE' => 'unset' do
        was_in_block = true
        assert_equal 'unset', ENV['UNSET_VARIABLE']
        raise "error"
        flunk "should not have reached here"
      end
    end

    assert_equal 'error', err.message
    assert_equal true, was_in_block
    assert_equal nil, ENV['UNSET_VARIABLE']
  end

  def test_with_env_replaces_env_if_specified
    ENV['SET_VARIABLE'] = 'set'

    was_in_block = false
    with_env({}, true) do
      was_in_block = true
      assert_equal nil, ENV['SET_VARIABLE']
      assert_equal false, ENV.has_key?('SET_VARIABLE')
    end

    assert_equal true, was_in_block
    assert_equal 'set', ENV['SET_VARIABLE']
  end

  def test_with_env_returns_block_result
    assert_equal "result", with_env {"result"}
  end

  def test_with_env_allows_nil_env
    was_in_block = false
    with_env(nil) do
      was_in_block = true
    end

    assert_equal true, was_in_block
  end
end