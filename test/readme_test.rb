require File.expand_path('../test_helper', __FILE__)
require 'shell_test'

class ReadmeTest < Test::Unit::TestCase
  include ShellTest
  LIBDIR = File.expand_path('../../lib', __FILE__)

  def test_shell_test_usage
    script = prepare('test.rb') do |io|
      io << outdent(%q{
      require 'shell_test/unit'
      class ShellTestTest < Test::Unit::TestCase
        include ShellTest

        def test_setting_variables_and_checking_stdout
          with_env("THING" => "moon") do
            assert_script %{
              % echo goodnight $THING
              goodnight moon
            }
          end
        end

        def test_multiple_commands
          assert_script %{
            % echo one
            one
            % echo two
            two
          }
        end

        def test_exit_statuses
          assert_script %{
            % true  # [0]
            % false # [1]
          }
        end

        def test_match_to_command_output
          assert_script_match %{
            % cal   # [0]
            :...:
            Su Mo Tu We Th Fr Sa
            :...:
          }
        end
      end
      })
    end
    
    result = sh "ruby -I'#{LIBDIR}' '#{script}'"
    assert_equal 0, $?.exitstatus, result
  end
  
  def test_file_methods_usage
    script = prepare('test.rb') do |io|
      io << outdent(%q{
      require 'shell_test/unit'
      class FileMethodsTest < Test::Unit::TestCase
        include ShellTest::FileMethods

        def test_make_a_temporary_file
          path = prepare('dir/file.txt') {|io| io << 'content' }
          assert_equal "content", File.read(path)
        end
      end
      })
    end

    result = sh "ruby -I'#{LIBDIR}' '#{script}'"
    assert_equal 0, $?.exitstatus, result
  end
  
  def test_subset_methods_usage
    script = prepare('test.rb') do |io|
      io << outdent(%q{
      require 'shell_test/unit'
      require 'rbconfig'

      class SubsetMethodsTest < Test::Unit::TestCase
        include ShellTest::SubsetMethods

        condition(:windows) do
          RbConfig::CONFIG['host_os'] =~ /mswin|windows|cygwin/i
        end

        def test_something_for_windows_only
          condition_test(:windows) do
            assert_match(/^[A-z]:/, __FILE__)
          end
        end
      end
      })
    end

    result = sh "ruby -I'#{LIBDIR}' '#{script}'"
    assert_equal 0, $?.exitstatus, result
  end
end
