require File.expand_path('../../test_helper', __FILE__)
require 'shell_test/file_methods'

class FileMethodsTest < Test::Unit::TestCase
  include ShellTest::FileMethods

  #
  # class_dir test
  #

  def test_include_guesses_class_dir_as_file_name_minus_extname
    assert_equal File.expand_path(__FILE__.chomp(File.extname(__FILE__))), class_dir
  end

  def test_class_dir_can_be_set_at_the_class_level
    path = prepare('file_test_parent_class.rb') do |io|
      io.puts %q{
        class FileMethodsAssignClassDir
          include ShellTest::FileMethods
          self.class_dir = 'custom'
        end
      }
    end
    require path

    assert_equal 'custom', FileMethodsAssignClassDir.class_dir
  end

  def test_subclass_guesses_class_dir_as_file_name_minus_extname
    path = prepare('file_test_parent_class.rb') do |io|
      io.puts %q{
        class FileMethodsParentClass
          include ShellTest::FileMethods
        end
      }
    end
    require path

    path = prepare('file_test_child_class.rb') do |io|
      io.puts %q{
        class FileMethodsChildClass < FileMethodsParentClass
        end
      }
    end
    require path

    assert_equal path('file_test_child_class'), FileMethodsChildClass.class_dir
  end

  def test_submodule_guesses_class_dir_as_file_name_minus_extname
    path = prepare('file_test_submodule.rb') do |io|
      io.puts %q{
        module FileMethodsSubmodule
          include ShellTest::FileMethods
        end
      }
    end
    require path

    path = prepare('file_test_include_submodule.rb') do |io|
      io.puts %q{
        class FileMethodsIncludeSubmodule
          include FileMethodsSubmodule
        end
      }
    end
    require path

    assert_equal path('file_test_include_submodule'), FileMethodsIncludeSubmodule.class_dir
  end

  #
  # keep_outputs? test
  #

  def test_keep_outputs_check_returns_true_if_KEEP_OUTPUTS_is_set_to_true_in_ENV
    current = ENV['KEEP_OUTPUTS']
    begin
      ENV['KEEP_OUTPUTS'] = nil
      assert_equal false, keep_outputs?

      ENV['KEEP_OUTPUTS'] = ''
      assert_equal false, keep_outputs?

      ENV['KEEP_OUTPUTS'] = 'true'
      assert_equal true, keep_outputs?
    ensure
      ENV['KEEP_OUTPUTS'] = current
    end
  end

  #
  # method_dir test
  #

  def test_method_dir_is_method_name_under_the_class_dir
    expected = File.expand_path('test_method_dir_is_method_name_under_the_class_dir', class_dir)
    assert_equal expected, method_dir
  end

  #
  # path test
  #

  def test_path_returns_relative_path_expanded_to_method_dir
    assert_equal File.expand_path('relative/path', method_dir), path('relative/path')
  end

  def test_path_raises_error_resulting_path_is_not_relative_to_method_dir
    err = assert_raises(RuntimeError) { path('../not_relative') }
    assert_equal 'does not make a path relative to method_dir: "../not_relative"', err.message
  end

  #
  # glob test
  #

  def test_glob_globs_the_pattern_under_method_dir
    a = prepare('a.txt')
    b = prepare('b')
    c = prepare('c.txt')

    assert_equal [a, b, c], glob('*').sort
    assert_equal [a, c], glob('*.txt').sort
  end

  #
  # prepare_dir test
  #

  def test_prepare_dir_makes_a_directory_and_all_parent_directories
    path = prepare_dir('a/b/c')
    assert_equal File.join(method_dir, 'a/b/c'), path
    assert_equal true, File.directory?(path)
  end

  #
  # _prepare test
  #

  def test__prepare_makes_a_file_and_all_parent_directories
    path = _prepare('dir/file')
    assert_equal true, File.exists?(path)
    assert_equal '', File.read(path)
  end

  def test_prepare_returns_an_absolute_path
    path = _prepare('dir/file')
    assert_equal File.expand_path(path), path
  end

  def test__prepare_accepts_content_via_a_block
    path = _prepare('dir/file') {|io| io << 'content' }
    assert_equal 'content', File.read(path)
  end

  def test__prepare_accepts_string_content
    path = _prepare('dir/file', %{
      content
    })
    assert_equal %{
      content
    }, File.read(path)
  end

  #
  # prepare test
  #

  def test_prepare_documentation
    path = prepare 'file', %{
      line one
      line two
    }
    assert_equal "line one\nline two\n", File.read(path)
  end

  def test_prepare_accepts_content_via_a_block
    path = prepare('dir/file') {|io| io << 'content' }
    assert_equal 'content', File.read(path)
  end

  def test_prepare_outdents_content
    path = prepare('dir/file', %{
      content
    })
    assert_equal "content\n", File.read(path)
  end

  #
  # content test
  #
  
  def test_content_returns_content_for_a_file_under_method_dir
    prepare('dir/file', 'content')
    assert_equal 'content', content('dir/file')
  end

  def test_content_allows_specification_of_length_and_offset
    prepare('dir/file', 'content')
    assert_equal 'on', content('dir/file', 2, 1)
  end

  def test_content_returns_nil_for_non_existant_files
    assert_equal nil, content('dir/file')
  end

  #
  # mode test
  #
  
  def test_mode_returns_the_formatted_string_mode_for_a_file_under_method_dir
    path = prepare('dir/file')
    FileUtils.chmod(0640, path)
    assert_equal '100640', mode('dir/file')
  end

  def test_mode_returns_nil_for_non_existant_files
    assert_equal nil, mode('dir/file')
  end

  #
  # remove test
  #

  def test_remove_removes_a_file_under_method_dir
    path = prepare('dir/file')
    dir  = File.dirname(path)
    remove(path)

    assert_equal false, File.exists?(path)
    assert_equal true, File.exists?(dir)
  end

  def test_remove_removes_a_directory_under_method_dir
    dir = prepare_dir('a/b')
    remove(dir)

    assert_equal false, File.exists?(dir)
  end

  def test_remove_raises_no_error_for_non_existant_paths
    path = path('dir/file')
    assert_equal false, File.exists?(path)

    remove(path)
    assert true
  end
end

class FileMethodsCleanupTest < Test::Unit::TestCase
  include ShellTest::FileMethods

  #
  # cleanup test
  #

  def test_cleanup_removes_method_dir_and_all_contents
    prepare('dir/file') {}
    cleanup
    assert_equal false, File.exists?(method_dir)
  end

  do_not_cleanup
  def test_do_not_cleanup_turns_off_cleanup_one
    prepare('dir/file') {}

    cleanup
    assert_equal true, File.exists?(method_dir)

    remove method_dir
  end

  cleanup :test_cleanup_may_be_turned_on_for_a_specific_method_using_cleanup
  def test_cleanup_may_be_turned_on_for_a_specific_method_using_cleanup
    prepare('dir/file') {}

    cleanup
    assert_equal false, File.exists?(method_dir)
  end

  define_paths_to_cleanup :test_cleanup_may_be_turned_on_for_a_specific_method_using_define_paths_to_cleanup, ['.']
  def test_cleanup_may_be_turned_on_for_a_specific_method_using_define_paths_to_cleanup
    prepare('a/file') {}

    cleanup
    assert_equal false, File.exists?(method_dir)
  end

  def test_do_not_cleanup_turns_off_cleanup_two
    prepare('dir/file') {}

    cleanup
    assert_equal true, File.exists?(method_dir)

    remove method_dir
  end

  cleanup
  def test_cleanup_turns_on_cleanup_one
    prepare('dir/file') {}

    cleanup
    assert_equal false, File.exists?(method_dir)
  end

  do_not_cleanup :test_cleanup_may_be_turned_off_for_a_specific_method
  def test_cleanup_may_be_turned_off_for_a_specific_method
    prepare('dir/file') {}

    cleanup
    assert_equal true, File.exists?(method_dir)

    remove method_dir
  end

  def test_cleanup_turns_on_cleanup_two
    prepare('dir/file') {}

    cleanup
    assert_equal false, File.exists?(method_dir)
  end

  default_paths_to_cleanup 'a', 'b'
  def test_default_paths_to_cleanup_defines_the_default_paths_to_cleanup
    prepare('a/x') {}
    prepare('a/y') {}
    prepare('b') {}
    prepare('c') {}

    cleanup

    assert_equal false, File.exists?(path('a'))
    assert_equal false, File.exists?(path('b'))
    assert_equal true, File.exists?(path('c'))

    remove method_dir
  end

  def test_default_paths_to_cleanup_persists_until_next_default_paths_to_cleanup_one
    prepare('b') {}
    prepare('c') {}

    cleanup

    assert_equal false, File.exists?(path('b'))
    assert_equal true, File.exists?(path('c'))

    remove method_dir
  end

  default_paths_to_cleanup '.'
  def test_default_paths_to_cleanup_persists_until_next_default_paths_to_cleanup_two
    prepare('b') {}
    prepare('c') {}

    cleanup

    assert_equal false, File.exists?(method_dir)
  end
end

class FileMethodsCleanupTestChild < FileMethodsCleanupTest
  # here to test inheritence
end