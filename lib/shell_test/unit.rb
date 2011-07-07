require 'test/unit'
require 'shell_test'

module ShellTest
  # ShellTest is designed to work with MiniTest, which is the standard testing
  # framework included in ruby 1.9.  Minor changes in the API break backward
  # compatibility with Test::Unit and/or add functionality expected by
  # ShellTest.
  #
  # Test::Unit can be patched by requiring the shim file before defining
  # specific TestCase subclasses.
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
  # Note that the shim script has only been tested vs the Test::Unit that
  # comes with ruby 1.8.x.  A Test::Unit 2.0 gem exists; use with caution.
  #
  # ==== Patches
  #
  # The shim script adds two things to Test::Unit:
  #
  # 1) A __name__ method which returns the test method name (alias for
  # method_name)
  #
  # 2) A skip method which can be used to skip a test (use it like flunk)
  #
  module Unit
  end
end

unless Object.const_defined?(:MiniTest)
  require 'shell_test/unit/shim'
end
