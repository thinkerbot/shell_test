require 'test/unit'
require 'shell_test'

module ShellTest
  # ShellTest is designed to work with MiniTest, which is the standard testing
  # framework included in ruby 1.9.  Minor changes in the API require shims to
  # be backward compatible.
  #
  # To manually apply the shim, extend Test::Unit::TestCase with the shim module
  # before defining specific TestCase subclasses.
  #
  #   require 'test/unit'
  #   unless Object.const_defined?(:MiniTest)
  #     require 'shell_test/unit/shim'
  #   end
  #
  # To let ShellTest do this for you:
  #
  #  require 'shell_test/unit'
  #
  module Unit
  end
end

unless Object.const_defined?(:MiniTest)
  require 'shell_test/unit/shim'
end
