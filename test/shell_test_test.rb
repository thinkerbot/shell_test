require File.expand_path('../test_helper', __FILE__)
require 'shell_test'

class ShellTestTest < Test::Unit::TestCase
  include ShellTest

  def test_include_adds_all_test_modules
    modules = self.class.included_modules
    assert modules.include?(ShellTest::ShellMethods)
    assert modules.include?(ShellTest::FileMethods)
  end

  def test_method_directories_are_setup_correctly
    expected = File.expand_path('../shell_test_test/test_method_directories_are_setup_correctly', __FILE__)
    assert_equal expected, method_dir
  end
  
  def test_skip
    skip
    flunk
  end
end