require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

TestUnitErrorClass = Object.const_defined?(:MiniTest) ? MiniTest::Assertion : Test::Unit::AssertionFailedError

if name = ENV['NAME']
  ARGV << "--name=#{name}"
end
