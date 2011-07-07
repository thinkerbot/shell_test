require 'test/unit'
require 'shell_test'

module ShellTest
  # ShellTest is designed to work with MiniTest, which is the standard testing
  # framework included in ruby 1.9.  Minor changes in the API require shims to
  # be backward compatible.
  #
  # To apply the shims, require the shim file before defining specific
  # TestCase subclasses.
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
  # ==== Changes
  #
  # The shims file hacks into the guts of Test::Unit to do two things:
  #
  # 1) A __name__ method is added which returns the test method name
  #
  # 2) A skip method is added to skip a test (use it like flunk)
  #
  module Unit
  end
end

unless Object.const_defined?(:MiniTest)
  require 'shell_test/unit/shim'
end
