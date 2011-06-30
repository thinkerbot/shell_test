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
#     Test::Unit::TestCase.extend ShellTest::Unit::Shim
#   end
#
# To let ShellTest do this for you:
#
#  require 'shell_test/unit'
#
module ShellTest
  module Unit
    module Shim
      # Alias method_name to __name__ such that FileMethods can redefine
      # method_name to call __name__.
      def self.extended(base)
        base.class_eval "alias __name__ method_name"
      end
    end
  end
end
