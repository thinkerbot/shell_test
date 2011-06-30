require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

if Object.const_defined?(:MiniTest) 
  TestUnitErrorClass = MiniTest::Assertion
else
  require 'shell_test/unit/shim'
  Test::Unit::TestCase.extend ShellTest::Unit::Shim
  TestUnitErrorClass = Test::Unit::AssertionFailedError
end

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
