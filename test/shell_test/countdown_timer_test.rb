require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/countdown_timer'

class CountdownTimerTest < Test::Unit::TestCase
  CountdownTimer = ShellTest::CountdownTimer

  module Instrumentation
    attr_reader :current_times

    def instrument_times(*current_times)
      @current_times = current_times
    end

    def current_time
      @current_times.shift
    end
  end

  attr_accessor :timer

  def setup
    super
    @timer = CountdownTimer.new 100
    @timer.extend Instrumentation
    @timer.instrument_times 0, 10, 20, 30, 40
  end

  #
  # initialize test
  #

  def test_initialize_sets_duration
    timer = CountdownTimer.new 100
    assert_equal 100, timer.duration
  end

  #
  # instrumentation test
  #

  def test_current_time_returns_instrumentation_times_in_order
    assert_equal 0, timer.current_time
    assert_equal 10, timer.current_time
    assert_equal 20, timer.current_time
    assert_equal 30, timer.current_time
    assert_equal 40, timer.current_time
  end

  #
  # start test
  #

  def test_start_sets_start_time_as_current_time
    timer.start
    assert_equal 0, timer.start_time
  end

  def test_start_sets_stop_time_as_start_time_plus_duration
    timer.start
    assert_equal 100, timer.stop_time
  end

  def test_start_sets_mark_time_as_stop_time
    timer.start
    assert_equal timer.stop_time, timer.mark_time
  end

  #
  # stop test
  #

  def test_stop_returns_time_elapsed_since_start_as_dictated_by_current_time
    timer.instrument_times 10, 18
    timer.start
    assert_equal 8, timer.stop
  end

  def test_stop_sets_times_to_zero
    timer.start
    timer.stop
    assert_equal 0, timer.start_time
    assert_equal 0, timer.stop_time
    assert_equal 0, timer.mark_time
  end

  #
  # time_to_stop test
  #

  def test_time_to_stop_returns_duration_from_current_time_to_stop_time
    timer.start
    assert_equal 90, timer.time_to_stop
    assert_equal 80, timer.time_to_stop
    assert_equal 70, timer.time_to_stop
  end

  def test_time_to_stop_returns_negative_if_current_time_is_past_stop_time
    timer.instrument_times 0, 110
    timer.start
    assert_equal 100, timer.stop_time
    assert_equal(-10, timer.time_to_stop)
  end

  #
  # set_mark test
  #

  def test_set_mark_sets_mark_time_relative_to_current_time
    timer.start
    timer.set_mark(50)
    assert_equal 60, timer.mark_time
  end

  def test_set_mark_preserves_current_mark_if_duration_is_negative
    timer.start
    timer.set_mark(50)
    assert_equal 60, timer.mark_time

    timer.set_mark(-1)
    assert_equal 60, timer.mark_time
  end

  def test_set_mark_sets_mark_time_to_stop_time_if_duration_is_nil
    timer.start
    assert_equal 100, timer.stop_time

    timer.set_mark(50)
    assert_equal 60, timer.mark_time

    timer.set_mark(nil)
    assert_equal 100, timer.mark_time
  end

  def test_set_mark_sets_mark_time_to_stop_time_if_greater_than_stop_time
    timer.start
    assert_equal 100, timer.stop_time

    timer.set_mark(200)
    assert_equal 100, timer.mark_time
  end

  #
  # time_to_mark test
  #

  def test_time_to_mark_returns_duration_from_current_time_to_mark_time
    timer.instrument_times 0, 0, 10, 20, 30
    timer.start
    timer.set_mark(50)
    assert_equal 40, timer.time_to_mark
    assert_equal 30, timer.time_to_mark
    assert_equal 20, timer.time_to_mark
  end

  def test_time_to_mark_returns_negative_if_current_time_is_past_mark_time
    timer.instrument_times 0, 110
    timer.start
    assert_equal 100, timer.mark_time
    assert_equal(-10, timer.time_to_mark)
  end
end