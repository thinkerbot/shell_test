require File.expand_path('../../../test_helper', __FILE__)
require 'shell_test/pty/step_timer'

class StepTimerTest < Test::Unit::TestCase
  StepTimer = ShellTest::Pty::StepTimer

  class Clock
    attr_reader :times

    def initialize(*times)
      @times = times
    end

    def now
      @times.shift
    end
  end

  attr_accessor :timer

  def setup
    super
    @timer = StepTimer.new
  end

  #
  # initialize test
  #

  def test_timeout_is_zero_by_default
    timer = StepTimer.new
    assert_equal 0, timer.timeout
  end

  #
  # start test
  #

  def test_start_sets_times_relative_to_current_time
    timer = StepTimer.new Clock.new(10)
    timer.start 100

    assert_equal 10,  timer.start_time
    assert_equal 110, timer.stop_time
    assert_equal 110, timer.step_time
  end

  #
  # stop test
  #

  def test_stop_returns_time_elapsed_since_start_as_determined_by_current_time
    timer = StepTimer.new Clock.new(0, 8)
    timer.start
    assert_equal 8, timer.stop
  end

  #
  # running? test
  #

  def test_running_check_returns_true_if_running
    timer = StepTimer.new
    assert_equal false, timer.running?
    timer.start
    assert_equal true, timer.running?
    timer.stop
    assert_equal false, timer.running?
  end

  #
  # timeout= test
  #

  def test_set_timeout_raises_error_if_not_running
    timer = StepTimer.new
    err = assert_raises(RuntimeError) { timer.timeout = 50 }
    assert_equal "cannot set timeout unless running", err.message
  end

  def test_set_timeout_sets_step_time_relative_to_now
    timer = StepTimer.new Clock.new(0, 10)
    timer.start 100

    timer.timeout = 50
    assert_equal 60, timer.step_time
  end

  def test_set_timeout_preserves_current_step_if_timeout_is_negative
    timer = StepTimer.new Clock.new(0, 10, 20)
    timer.start 100

    timer.timeout = 50
    assert_equal 60, timer.step_time

    timer.timeout = -1
    assert_equal 60, timer.step_time
  end

  def test_set_timeout_sets_step_time_to_stop_time_if_timeout_is_nil
    timer = StepTimer.new Clock.new(0)
    timer.start 100

    timer.timeout = nil
    assert_equal 100, timer.step_time
  end

  def test_set_timeout_sets_step_time_to_stop_time_if_step_time_would_be_greater_than_stop_time
    timer = StepTimer.new Clock.new(0, 80)
    timer.start 100

    timer.timeout = 30
    assert_equal 100, timer.step_time
  end

  #
  # timeout test
  #

  def test_timeout_returns_duration_from_now_to_step_time
    timer = StepTimer.new Clock.new(0, 0, 10, 20, 30)
    timer.start 100
    timer.timeout = 50

    assert_equal 40, timer.timeout
    assert_equal 30, timer.timeout
    assert_equal 20, timer.timeout
  end

  def test_timeout_returns_zero_if_now_is_past_step_time
    timer = StepTimer.new Clock.new(0, 0, 110)
    timer.start 100
    timer.timeout = 100

    assert_equal 0, timer.timeout
  end
end