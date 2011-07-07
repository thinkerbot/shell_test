require 'test/unit/error'
module ShellTest
  module Unit
    class Skip < Test::Unit::Error
      # Returns a single character representation of a failure.
      def single_character_display
        "S"
      end

      # Returns the message associated with the error.
      def message
        @exception.message
      end

      # Returns a verbose version of the error description.
      def long_display
        backtrace = filter_backtrace(@exception.backtrace)
        "Skipped:\n#@test_name [#{backtrace[0].sub(/:in `.*$/, "")}]:\n#{message}\n"
      end
    end
  end
end

require 'test/unit/testresult'
class Test::Unit::TestResult
  alias shell_test_original_to_s to_s
  
  # Returns skips recorded for self.
  def skips
    @skips ||= []
  end
  
  # Records a Test::Unit::Error (including Skip errors).
  def add_error(error)
    if error.kind_of?(ShellTest::Unit::Skip)
      skips << error
    else
      @errors << error
    end
    
    notify_listeners(FAULT, error)
    notify_listeners(CHANGED, self)
  end

  # Adds the skip count to the summary
  def to_s
    "#{shell_test_original_to_s}, #{skips.length} skips"
  end
end

require 'test/unit/testcase'
class Test::Unit::TestCase
  class SkipException < StandardError; end

  alias __name__ method_name

  def skip msg = nil, bt = caller
    msg ||= "Skipped, no message given"
    raise SkipException, msg, bt
  end

  def add_error(exception)
    @test_passed = false
    @_result.add_error(error_class(exception).new(name, exception))
  end
  
  def error_class(exception)
    exception.kind_of?(SkipException) ? ShellTest::Unit::Skip : Test::Unit::Error
  end
end
