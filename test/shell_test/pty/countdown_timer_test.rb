require File.expand_path('../../../test_helper', __FILE__)
require 'shell_test/pty/countdown_timer'

class CountdownTimerTest < Test::Unit::TestCase
  CountdownTimer = ShellTest::Pty::CountdownTimer

  class Clock
    attr_reader :times

    def initialize(*times)
      @times = times
    end

    def now
      @times.shift
    end
  end

  #
  # initialize test
  #

  def test_timeout_is_zero_by_default
    timer = CountdownTimer.new Clock.new(10)
    assert_equal 0, timer.timeout
  end

  #
  # timeout= test
  #

  def test_set_timeout_sets_stop_time_to_now_plus_timeout
    timer = CountdownTimer.new Clock.new(10)
    timer.timeout = 100
    assert_equal 110, timer.stop_time
  end

  def test_set_timeout_sets_stop_time_to_nil_if_timeout_is_nil
    timer = CountdownTimer.new Clock.new(10)
    timer.timeout = nil
    assert_equal nil, timer.stop_time
  end

  #
  # timeout test
  #

  def test_timeout_returns_duration_from_now_to_stop_time
    timer = CountdownTimer.new Clock.new(80, 90, 100)
    timer.stop_time = 100
    assert_equal 20, timer.timeout
    assert_equal 10, timer.timeout
    assert_equal 0,  timer.timeout
  end

  def test_timeout_returns_zero_if_now_is_past_stop_time
    timer = CountdownTimer.new Clock.new(110)
    timer.stop_time = 100
    assert_equal 0, timer.timeout
  end

  def test_timeout_returns_nil_if_stop_time_is_nil
    timer = CountdownTimer.new
    timer.stop_time = nil
    assert_equal nil, timer.timeout
  end
end
