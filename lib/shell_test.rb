require 'shell_test/version'
require 'shell_test/file_methods'
require 'shell_test/shell_methods'

module ShellTest
  include FileMethods
  include ShellMethods
end
