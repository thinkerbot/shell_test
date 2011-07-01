require File.expand_path('../../test_helper.rb', __FILE__) 
require 'shell_test/subset_methods'

class SubsetMethodsTest < Test::Unit::TestCase
  include ShellTest::SubsetMethods

  #
  # condition test
  #

  condition(:is_true) {true}
  condition(:is_false) {false}

  def test_conditional_test_runs_only_if_all_conditions_are_true
    test_ran = false
    condition_test(:is_true) { test_ran = true}
    assert test_ran

    test_ran = false
    condition_test(:is_false) { test_ran = true}
    assert !test_ran

    test_ran = false
    condition_test(:is_true, :is_false) { test_ran = true}
    assert !test_ran
  end
end

#
# inheritance test
#

class SubsetMethodsBaseTest < Test::Unit::TestCase
  include ShellTest::SubsetMethods
  condition(:condition) { true }

  def test_condition
    assert condition_satisfied?(:condition)
  end
end

class SubsetMethodsInheritanceTest < SubsetMethodsBaseTest
  def test_condition
    assert condition_satisfied?(:condition)
  end
end

class SubsetMethodsOverrideTest < SubsetMethodsBaseTest
  condition(:condition) { false }

  def test_condition
    assert !condition_satisfied?(:condition)
  end
end

module SubsetConditions
  include ShellTest::SubsetMethods
  condition(:is_true) { true }
end

class SubsetIncludeTest < Test::Unit::TestCase
  include SubsetConditions
  
  def test_condition
    assert condition_satisfied?(:is_true)
  end
end

#
# Documentation Tests
#

class ShellTestExample < Test::Unit::TestCase
  include ShellTest::SubsetMethods
  condition(:never_run)   { false }

  def test_using_conditions
    condition_test(:never_run) { flunk }
  end
end

module Conditions
  include ShellTest::SubsetMethods
  condition(:is_true) { true }
end

class IncludeConditionsTest < Test::Unit::TestCase
  include Conditions

  def test_included_condition
    condition_test(:is_true) { assert true }
  end
end
