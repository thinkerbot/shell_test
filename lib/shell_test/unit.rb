require 'test/unit'
require 'shell_test'

unless Object.const_defined?(:MiniTest)
  require 'shell_test/unit/shim'
  Test::Unit::TestCase.extend ShellTest::Unit::Shim
end
