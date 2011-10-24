require File.expand_path('../test_helper', __FILE__)
require 'shell_test'

class ReadmeTest < Test::Unit::TestCase
  include ShellTest
  LIBDIR = File.expand_path('../../lib', __FILE__)

  def test_shell_test_example
    script = prepare('test.rb') do |io|
      io << outdent(%q{
        require 'shell_test/unit'

        class ShellTestExample < Test::Unit::TestCase
          include ShellTest

          def test_a_script
            script = prepare('script.sh') do |io|
              io.puts "echo goodnight $1"
            end

            assert_script %{
              $ sh '#{script}' moon
              goodnight moon
            }, :exitstatus => 0
          end
        end
      })
    end
    
    result = `ruby -I'#{LIBDIR}' '#{script}'`
    assert_equal 0, $?.exitstatus, indent(result, '    ')
  end
  
  def test_shell_methods_example
    script = prepare('test.rb') do |io|
      io << outdent(%q{
        require 'shell_test/unit'

        class ShellMethodsExample < Test::Unit::TestCase
          include ShellTest::ShellMethods

          def test_a_script_with_env_variables
            with_env("THIS" => "moon") do
              assert_script %{
                $ THAT="boat"
                $ echo "goodnight $THIS"
                goodnight moon
                $ echo "goodnight $THAT"
                goodnight boat
              }
            end
          end

          def test_multiline_commands
            assert_script %{
              $ for n in one two; do
              >   echo $n
              > done
              one
              two
            }
          end

          def test_script_with_overall_and_per_command_timeouts
            assert_script %{
              $ sleep 0.1  # [0.5]
              $ sleep 0.1  # [0.5]
            }, :max_run_time => 1
          end

          def test_scripts_where_the_output_is_variable
            assert_script_match %{
              $ cal
              :...:
              Su Mo Tu We Th Fr Sa:. *.:
              :....:
            }
          end

          def test_scripts_that_take_input
            assert_script %{
              $ sudo echo 'sorry i cant do that dave'
              Password:{{notIt}}
              Sorry, try again.
              Password:{{mayBeThis}}
              Sorry, try again.
              Password:{{cr@pWhatIsIt}}
              Sorry, try again.
              sudo: 3 incorrect password attempts
            }, :max_run_time => 10
          end
        end
      })
    end
    
    result = `ruby -I'#{LIBDIR}' '#{script}'`
    assert_equal 0, $?.exitstatus, indent(result, '    ')
  end
  
  def test_file_methods_example
    script = prepare('test.rb') do |io|
      io << outdent(%q{
        require 'shell_test/unit'

        class FileMethodsExample < Test::Unit::TestCase
          include ShellTest::FileMethods

          def test_preparation_of_a_test_specific_file
            path = prepare('dir/file.txt') {|io| io << 'content' }
            assert_equal "content", File.read(path)
          end
        end
      })
    end

    result = `ruby -I'#{LIBDIR}' '#{script}'`
    assert_equal 0, $?.exitstatus, indent(result, '    ')
  end
end
