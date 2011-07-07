require 'test/unit/testresult'
class Test::Unit::TestResult
  alias shell_test_original_to_s to_s

  # The current skip count
  def skip_count
    @skip_count ||= 0
  end

  # Records a skipped test run.
  def add_skip
    @skip_count = skip_count + 1
    notify_listeners(CHANGED, self)
  end

  # Adds the skip count to the summary
  def to_s
    "#{shell_test_original_to_s}, #{skip_count} skipped"
  end
end

require 'test/unit/testcase'
class Test::Unit::TestCase
  class SkipException < StandardError; end
  PASSTHROUGH_EXCEPTIONS << SkipException

  alias __name__ method_name
  alias shell_test_original_run run

  def skip msg = nil, bt = caller
    msg ||= "Skipped, no message given"
    raise SkipException, msg, bt
  end

  def run(result, &block)
    begin
      shell_test_original_run(result, &block)
    rescue SkipException
      result.add_skip
      yield(FINISHED, name)
    end
  end
end