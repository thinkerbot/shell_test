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
            }
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

          def test_a_script_using_variables
            with_env("THING" => "moon") do
              assert_script %{
                $ echo "goodnight $THING"
                goodnight moon
              }
            end
          end

          def test_multiple_commands
            assert_script %{
              $ echo one
              one
              $ echo two
              two
            }
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

          def test_exit_status
            assert_script %{
              $ false
            }, :exitstatus => 1
          end

          def test_output_with_inline_regexps
            assert_script_match %{
              $ cal
              :...:
              Su Mo Tu We Th Fr Sa:. *.:
              :....:
            }
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
