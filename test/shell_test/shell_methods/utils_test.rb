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

  def test_spawn_returns_block_result
    result = spawn('/bin/sh') do |master, slave|
      master.write "exit 8\n"
      :result
    end

    assert_equal :result, result
  end
end