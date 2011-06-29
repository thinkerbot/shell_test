require 'benchmark'

module ShellTest

  # SubsetMethods provides methods to conditionally run tests.
  #  
  #   require 'shell_test'
  #
  #   class Test::Unit::TestCase
  #     # only true if running on windows
  #     condition(:windows) { match_platform?('mswin') }
  #  
  #     # only true if running on anything but windows
  #     condition(:non_windows) { match_platform?('non_mswin') }
  #   end
  #
  # Here the WindowsOnlyTest will only run on a Windows platform. Conditions
  # like these may be targeted at specific tests when only some tests need
  # to be skipped.
  #  
  #   class RunOnlyAFewTest < Test::Unit::TestCase
  #     include SubsetMethods
  #  
  #     def test_runs_all_the_time
  #       assert true
  #     end
  #  
  #     def test_runs_only_if_non_windows_condition_is_true
  #       condition_test(:non_windows) { assert true }
  #       end
  #     end
  #  
  #     def test_runs_only_when_ENV_variable_EXTENDED_is_true
  #       extended_test { assert true }
  #     end
  #  
  #     def test_runs_only_when_ENV_variable_BENCHMARK_is_true
  #       benchmark_test do |x|
  #         x.report("init speed") { 10000.times { Object.new } }
  #       end
  #     end
  #
  #     def test_runs_only_when_ENV_variable_CUSTOM_is_true
  #       subset_test('CUSTOM') { assert true }
  #     end
  #   end
  #  
  # In the example, the ENV variables EXTENDED, BENCHMARK, and CUSTOM act as
  # flags to run specific tests.  See SubsetMethods::ClassMethods for more
  # information.
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
    
      # Returns true if RUBY_PLATFORM matches one of the specfied
      # platforms.  Use the prefix 'non_' to specify any plaform 
      # except the specified platform (ex: 'non_mswin').  Returns
      # true if no platforms are specified.
      #
      # Some common platforms:
      #   mswin    Windows
      #   darwin   Mac
      def match_platform?(*platforms)
        platforms.each do |platform|
          platform.to_s =~ /^(non_)?(.*)/

          non = true if $1
          match_platform = !RUBY_PLATFORM.index($2).nil?
          return false unless (non && !match_platform) || (!non && match_platform)
        end

        true
      end
    
      # Returns true if type or 'ALL' is specified as 'true' in ENV.
      def run_subset?(type)
        ENV[type] == "true" || ENV['ALL'] == "true" ? true : false
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

    # Returns true if the subset type (ex 'BENCHMARK') or 'ALL' is
    # specified in ENV.
    def run_subset?(type)
      self.class.run_subset?(type)
    end

    # Returns true if the input string matches the regexp specified in 
    # ENV[type]. Returns the default value if ENV['ALL'] is 'true', and the
    # default if type is not specified in ENV.
    def match_regexp?(type, str, default=true)
      return true if ENV["ALL"] == 'true'
      return default unless value = ENV[type]

      str =~ Regexp.new(value) ? true : false
    end

    # Platform-specific test.  Useful for specifying test that should only 
    # be run on a subset of platforms.  Prints ' ' if the test is not run.
    #
    #   def test_only_on_windows
    #     platform_test('mswin') { ... }
    #   end
    #
    # See SubsetMethodsClass#match_platform? for matching details.
    def platform_test(*platforms)
      if self.class.match_platform?(*platforms)
        yield
      else
        print ' '
      end
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
      if self.class.unsatisfied_conditions(*condition_names).empty?
        yield
      else
        print ' '
      end
    end

    # Defines a subset test.  The provided block will only run if:
    # - the subset type is specified in ENV
    # - the subset 'ALL' is specified in ENV
    # - the test method name matches the regexp provided in the 
    #   <TYPE>_TEST ENV variable
    #  
    # Otherwise the block will be skipped and +skip+ will be printed in the
    # test output.  By default skip is the first letter of +type+.
    #
    # For example, with these methods:
    #
    #   def test_one
    #     subset_test('CUSTOM') { assert true }
    #   end
    #
    #   def test_two
    #     subset_test('CUSTOM') { assert true }
    #   end
    #
    #   Condition                    Tests that get run
    #   ENV['ALL']=true              test_one, test_two
    #   ENV['CUSTOM']=true           test_one, test_two
    #   ENV['CUSTOM_TEST']=test_     test_one, test_two
    #   ENV['CUSTOM_TEST']=test_one  test_one
    #   ENV['CUSTOM']=nil            no tests get run
    # 
    # If you're running your tests with rake (or rap), ENV variables may be
    # set from the command line.
    #
    #   # all tests
    #   % rap test all=true
    #
    #   # custom subset tests
    #   % rap test custom=true
    #
    #   # just test_one (it is the only test
    #   # matching the '.est_on.' pattern)
    #   % rap test custom_test=.est_on.
    #
    def subset_test(type, skip=type[0..0].downcase)
      type = type.upcase
      if run_subset?(type) || ENV["#{type}_TEST"]
        if match_regexp?("#{type}_TEST", name.to_s)
          yield
        else
          print skip
        end
      else
        print skip
      end
    end

    # Declares a subset_test for the ENV variable 'EXTENDED'.
    # Prints 'x' if the test is not run.
    #
    #   def test_some_long_process
    #     extended_test { ... }
    #   end
    def extended_test(&block) 
      subset_test("EXTENDED", "x", &block)
    end

    # Declares a subset_test for the ENV variable 'BENCHMARK'. If run, 
    # benchmark_test sets up benchmarking using the Benchmark.bm method 
    # using the input length and block.  Prints 'b' if the test is not run.
    #
    #   include Benchmark
    #   def test_speed
    #     benchmark_test(10) {|x| ... }
    #   end
    def benchmark_test(length=10, &block) 
      subset_test("BENCHMARK") do
        puts
        puts name
        Benchmark.bm(length, &block)
      end
    end
  end
end