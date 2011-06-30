require 'benchmark'

module ShellTest

  # SubsetMethods provides methods to conditionally run tests.
  # 
  #   require 'shell_test/unit'
  #   
  #   class ShellTestExample < Test::Unit::TestCase
  #     include ShellTest::SubsetMethods
  #     condition(:never_run)   { false }
  #   
  #     def test_using_conditions
  #       condition_test(:never_run) { flunk }
  #     end
  #   end
  #
  # Any kind of conditions may be checked by the block - if it returns truthy
  # then the condition test will run.  Note the condition block is evaluated
  # every time the condition is used in a test.
  module SubsetMethods
    # Class methods associated with SubsetTest.
    module ClassMethods

      # Passes conditions to subclass
      def inherited(child) # :nodoc:
        super
        dup = {}
        conditions.each_pair {|key, value| dup[key] = value.dup }
        child.instance_variable_set(:@conditions, dup)
      end

      # Initialize conditions.
      def self.extended(base) # :nodoc:
        base.instance_variable_set(:@conditions, {})
      end

      # A hash of [name, [msg, condition_block]] pairs defined by condition.
      attr_reader :conditions

      # Defines a condition block and associated message.  
      # Raises an error if no condition block is given.
      def condition(name, msg=nil, &block)
        raise ArgumentError, "no condition block given" unless block_given?
        conditions[name] = [msg, block]
      end

      # Returns true if the all blocks for the specified conditions return true.
      #
      #   condition(:is_true) { true }
      #   condition(:is_false) { false }
      #   satisfied?(:is_true)              # => true
      #   satisfied?(:is_true, :is_false)   # => false
      #
      # Yields the name and message for each unsatisfied condition to the
      # block, if given.
      def satisfied?(*names) # :yields: name-of-unsatisfied-condition, msg
        unsatisfied = unsatisfied_conditions(*names)

        unsatisfied.each do |name| 
          yield(name, condition[name][0])
        end if block_given?

        unsatisfied.empty?
      end

      # Returns an array of the unsatified conditions.  Raises 
      # an error if a condition has not been defined.
      #
      #   condition(:is_true) { true }
      #   condition(:is_false) { false }
      #   unsatisfied_conditions(:is_true, :is_false)   # => [:is_false]
      #
      def unsatisfied_conditions(*condition_names)
        condition_names = conditions.keys if condition_names.empty?
        unsatified = []
        condition_names.each do |name|
          unless condition = conditions[name]
            raise ArgumentError, "Unknown condition: #{name}"
          end

          unsatified << name unless condition.last.call
        end
        unsatified
      end
    end

    def self.included(base) # :nodoc:
      super
      base.extend SubsetMethods::ClassMethods
    end

    # Returns true if the specified conditions are satisfied.
    def satisfied?(*condition_names)
      self.class.satisfied?(*condition_names)
    end

    # Conditonal test.  Only runs if the specified conditions are satisfied.
    # If no conditons are explicitly set, condition_test only runs if ALL 
    # conditions for the test are satisfied.
    # 
    #   condition(:is_true) { true }
    #   condition(:is_false) { false }
    #
    #   def test_only_if_true_is_satisfied
    #     condition_test(:is_true) { # runs }
    #   end
    #
    #   def test_only_if_all_conditions_are_satisfied
    #     condition_test {  # does not run }
    #   end
    #
    # See SubsetMethodsClass#condition for more details.
    def condition_test(*condition_names)
      if satisfied?(*condition_names)
        yield
      else
        print ' '
      end
    end
  end
end