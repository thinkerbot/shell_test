module ShellTest

  # SubsetMethods provides methods to conditionally run tests - if the
  # condition block return truthy then any associated tests will run.
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
  # Conditions may also be declared in modules for reuse.
  #
  #   module Conditions
  #     include ShellTest::SubsetMethods
  #     condition(:is_true) { true }
  #   end
  #   
  #   class IncludeConditionsTest < Test::Unit::TestCase
  #     include Conditions
  #   
  #     def test_included_condition
  #       condition_test(:is_true) { assert true }
  #     end
  #   end
  #
  # Multiple conditions can be specified in a given condition_test.  The
  # conditions are evaluated every time they are used by condition_test.
  module SubsetMethods
    module ClassMethods
      # A hash of (key, [msg, condition_block]) pairs tracking conditions
      # defined on self.  See the conditions method for all conditions
      # declared across all ancestors.
      attr_accessor :condition_registry

      def self.initialize(base)
        base.reset_conditions
        unless base.instance_variable_defined?(:@condition_registry)
          base.instance_variable_set(:@condition_registry, {})
        end
      end

      # A hash of (name, [msg, condition_block]) pairs defined by condition.
      def conditions
        @conditions ||= begin
          conditions = {}

          ancestors.reverse.each do |ancestor|
            next unless ancestor.kind_of?(ClassMethods)
            ancestor.condition_registry.each_pair do |key, value|
              if value.nil?
                conditions.delete(key)
              else
                conditions[key] = value
              end
            end
          end

          conditions
        end
      end

      # Resets conditions such that they will be recalculated.
      def reset_conditions
        @conditions = nil
      end

      # Defines a condition block and associated message.  Raises an error if
      # no condition block is given.
      def condition(name, msg=nil, &block)
        raise ArgumentError, "no condition block given" unless block_given?
        condition_registry[name] = [msg, block]
      end

      # Removes a condition much like undef_method undefines a method. 
      def remove_condition(name)
        unless condition_registry.has_name?(name)
          raise NameError.new("#{name.inspect} not set on #{self}")
        end
        condition_registry.delete(name)
        reset_conditions
      end

      # Undefines a condition much like undef_method undefines a method. 
      def undef_condition(name)
        unless conditions.has_name?(name)
          raise NameError.new("#{name.inspect} not defined in #{self}")
        end
        condition_registry[name] = nil
        reset_conditions
      end

      # Returns true if the all blocks for the specified conditions return
      # true.
      #
      #   condition(:is_true) { true }
      #   condition(:is_false) { false }
      #   condition_satisfied?(:is_true)              # => true
      #   condition_satisfied?(:is_true, :is_false)   # => false
      #
      # Yields the name and message for each unsatisfied condition to the
      # block, if given.
      def condition_satisfied?(*condition_names)
        unsatisfied = unsatisfied_conditions(*condition_names)

        unsatisfied.each do |name|
          msg = condition[name][0]
          yield(name, msg)
        end if block_given?

        unsatisfied.empty?
      end

      # Returns an array of the unsatified conditions.  Raises an error if a
      # condition has not been defined.
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

          condition_block = condition[1]
          unsatified << name unless condition_block.call
        end
        unsatified
      end

      private

      def inherited(base)
       ClassMethods.initialize(base)
       super
      end
    end

    module ModuleMethods
      module_function

      def included(base)
        base.extend ClassMethods
        base.extend ModuleMethods unless base.kind_of?(Class)

        ClassMethods.initialize(base)
        super
      end
    end

    extend ModuleMethods

    # Returns true if the specified conditions are satisfied.
    def condition_satisfied?(*condition_names)
      self.class.condition_satisfied?(*condition_names)
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
      if condition_satisfied?(*condition_names)
        yield
      else
        print ' '
      end
    end
  end
end