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

class SubsetBaseTest < Test::Unit::TestCase
  include ShellTest::SubsetMethods

  if !conditions.empty?
    raise "conditions were NOT empty in subset class"
  end

  condition(:satisfied) do 
    true
  end

  def test_class_level_condition
    assert satisfied?(:satisfied)
  end
end

class SubsetInheritanceTest < SubsetBaseTest
  if conditions.empty?
    raise "conditions WERE empty in subclass"
  end

  def test_class_level_condition
    assert satisfied?(:satisfied)
  end
end

class SubsetOverrideTest < SubsetBaseTest
  if conditions.empty?
    raise "conditions WERE empty in subclass"
  end

  condition(:satisfied) do 
    false
  end

  def test_class_level_condition
    assert !satisfied?(:satisfied)
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
