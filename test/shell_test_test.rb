require File.expand_path('../test_helper', __FILE__)
require 'shell_test'

class ShellTestTest < Test::Unit::TestCase
  include ShellTest

  def test_include_adds_all_test_modules
    modules = self.class.included_modules
    assert modules.include?(ShellTest::SubsetMethods)
    assert modules.include?(ShellTest::ShellMethods)
    assert modules.include?(ShellTest::FileMethods)
  end
end