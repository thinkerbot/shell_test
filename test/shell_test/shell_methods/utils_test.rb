require File.expand_path("../../../test_helper", __FILE__)
require "shell_test/shell_methods/utils"

class UtilsTest < Test::Unit::TestCase
  include ShellTest::ShellMethods::Utils

  #
  # spawn test
  #

  def test_spawn_returns_exit_status
    status = spawn('/bin/sh') do |master, slave|
      master.write "exit 8\n"
    end
    assert_equal 8, status.exitstatus
  end
end