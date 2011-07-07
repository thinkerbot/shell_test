# :stopdoc:
module ShellTest
  module Unit
    
    # An exception class to flag skips.
    class SkipException < StandardError
    end
    
    # Modifies how errors related to a SkipException are displayed.
    module SkipDisplay
      # Display S rather than E in the progress.
      def single_character_display
        "S"
      end

      # Removes the exception class from the message.
      def message
        @exception.message
      end

      # Updates the output to look like a MiniTest skip error.
      def long_display
        backtrace = filter_backtrace(@exception.backtrace)
        "Skipped:\n#@test_name [#{backtrace[0].sub(/:in `.*$/, "")}]:\n#{message}\n"
      end
    end
  end
end

require 'test/unit/testresult'
class Test::Unit::TestResult
  # Returns an array of skips recorded for self.
  def skips
    @skips ||= []
  end

  # Partition errors from a SkipException from other errors and records as
  # them as skips (the error is extended to display as a skip).
  def add_error(error)
    if error.exception.kind_of?(ShellTest::Unit::SkipException)
      error.extend ShellTest::Unit::SkipDisplay
      skips << error
    else
      @errors << error
    end

    notify_listeners(FAULT, error)
    notify_listeners(CHANGED, self)
  end

  alias shell_test_original_to_s to_s

  # Adds the skip count to the summary.
  def to_s
    "#{shell_test_original_to_s}, #{skips.length} skips"
  end
end

require 'test/unit/testcase'
class Test::Unit::TestCase
  # Alias method_name to __name__ such that FileMethods can redefine
  # method_name to call __name__ (circular I know, but necessary for
  # compatibility with MiniTest)
  alias __name__ method_name

  # Call to skip a test.
  def skip(msg = nil, bt = caller)
    msg ||= "Skipped, no message given"
    raise ShellTest::Unit::SkipException, msg, bt
  end
end
# :startdoc: