require 'fileutils'
require 'shell_test/string_methods'

module ShellTest
  module FileMethods
    module ClassMethods
      attr_accessor :class_dir

      # A registry tracking paths_to_cleanup for the current class.
      attr_reader :paths_to_cleanup_registry

      # A hash of (method_name, [relative_path]) pairs identifying which
      # relative paths on each method have been marked on this class or
      # inherited from ancestors. Entries in paths_to_cleanup should not be
      # edited directly.  Instead use:
      #
      #   cleanup         : turn on cleanup for methods
      #   do_not_cleanup  : turn off cleanup for methods
      #   default_paths_to_cleanup : set the default paths to cleanup
      # 
      # Or if you need very precise editing, use (with the same semantics as
      # {define/remove/undef}_method):
      #
      #   define_paths_to_cleanup
      #   remove_paths_to_cleanup
      #   undef_paths_to_cleanup
      #
      def paths_to_cleanup
        @paths_to_cleanup ||= begin
          paths_to_cleanup = {}

          ancestors.reverse.each do |ancestor|
            next unless ancestor.kind_of?(ClassMethods)
            ancestor.paths_to_cleanup_registry.each_pair do |key, value|
              if value.nil?
                paths_to_cleanup.delete(key)
              else
                paths_to_cleanup[key] = value
              end
            end
          end

          paths_to_cleanup
        end
      end

      # Resets paths_to_cleanup such that it will be recalculated.
      def reset_paths_to_cleanup
        @paths_to_cleanup = nil
      end

      protected

      def self.initialize(base)
        # Infers the test directory from the calling file.
        #   'some_class_test.rb' => 'some_class_test'
        call_line = caller.find {|value| value !~ /`(includ|inherit|extend)ed'$/ }

        if call_line
          calling_file   = call_line.gsub(/:\d+(:in .*)?$/, "")
          base.class_dir = calling_file.chomp(File.extname(calling_file))
        else
          unless Dir.respond_to?(:tmpdir)
            require 'tmpdir'
          end
          base.class_dir = Dir.tmpdir
        end

        base.reset_paths_to_cleanup
        unless base.instance_variable_defined?(:@paths_to_cleanup_registry)
          base.instance_variable_set(:@paths_to_cleanup_registry, {})
        end

        unless base.instance_variable_defined?(:@default_paths_to_cleanup)
          base.instance_variable_set(:@default_paths_to_cleanup, ['.'])
        end

        unless base.instance_variable_defined?(:@cleanup)
          base.instance_variable_set(:@cleanup, true)
        end
      end

      def inherited(base) # :nodoc:
        ClassMethods.initialize(base)
        super
      end

      # Define the paths_to_cleanup for the specified method.  The settings
      # are inherited, but can be overridden in subclasses.
      def define_paths_to_cleanup(method_name, relative_paths)
        reset_paths_to_cleanup
        paths_to_cleanup_registry[method_name.to_sym] = relative_paths
      end

      # Remove the paths_to_cleanup for the method as defined on self.  The
      # paths_to_cleanup inherited from ancestors will still be in effect.
      def remove_paths_to_cleanup(method_name)
        reset_paths_to_cleanup
        paths_to_cleanup_registry.delete(method_name.to_sym)
      end

      # Undefines the paths_to_cleanup for the method, preventing inheritance
      # from ancestors.
      def undef_paths_to_cleanup(method_name)
        reset_paths_to_cleanup
        paths_to_cleanup_registry[method_name.to_sym] = nil
      end

      # Sets the default paths_to_cleanup for subsequent methods.
      def default_paths_to_cleanup(*relative_paths)
        @default_paths_to_cleanup = relative_paths
      end

      # Mark the methods for cleanup using the default_paths_to_cleanup.  Call
      # without method names to mark all subsequent methods for cleanup.
      def cleanup(*method_names)
        if method_names.empty?
          @cleanup = true
        else
          method_names.each do |method_name|
            define_paths_to_cleanup method_name, @default_paths_to_cleanup
          end
        end
      end

      # Prevent cleanup for the methods.  Call without method names to prevent
      # cleanup for subsequent methods.
      def do_not_cleanup(*method_names)
        if method_names.empty?
          @cleanup = false
        else
          method_names.each do |method_name|
            undef_paths_to_cleanup method_name
          end
        end
      end

      # Returns true if the method should be marked for cleanup when added.
      def mark_for_cleanup?(method_name)
        @cleanup && !paths_to_cleanup_registry.has_key?(method_name.to_sym) && method_name.to_s.index("test_") == 0
      end

      # Overridden to ensure methods marked for cleanup are cleaned up.
      def method_added(sym)
        super
        if mark_for_cleanup?(sym)
          cleanup sym
        end
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

    include StringMethods
    extend ModuleMethods

    # Returns the absolute path to the current working directory.
    attr_reader :user_dir

    # Calls cleanup to remove any files left over from previous test runs (for
    # instance by running with a flag to keep outputs).
    def setup
      super
      @user_dir = Dir.pwd
      cleanup
    end

    # Generic cleanup method.  Returns users to the user_dir then calls
    # cleanup unless keep_outputs? returns true.  If cleanup is called, any
    # empty directories under method_dir are also removed.
    #
    # Be sure to call super if teardown is overridden in a test case.
    def teardown
      Dir.chdir(user_dir)

      unless keep_outputs?
        cleanup

        dir = method_dir
        while dir != class_dir
          dir = File.dirname(dir)
          Dir.rmdir(dir)
        end rescue(SystemCallError)
      end

      super
    end

    # Returns true if KEEP_OUTPUTS is set to 'true' in ENV.
    def keep_outputs?
      ENV["KEEP_OUTPUTS"] == "true"
    end

    # Returns the absolute path to a directory specific to the current test
    # class, specifically the class.class_dir expanded relative to the
    # user_dir.
    def class_dir
      @class_dir  ||= File.expand_path(self.class.class_dir, user_dir)
    end

    # Returns the absolute path to a directory specific to the current test
    # method, specifically method_name expanded relative to class_dir.
    def method_dir
      @method_dir ||= File.expand_path(method_name.to_s, class_dir)
    end

    # Returns the method name of the current test.
    #
    # Really this method is an alias for __name__ which is present in
    # MiniTest::Unit and reproduces the method_name in Test::Unit.
    # ShellTest::Unit ensures this method is set up correctly in those
    # frameworks.  If this module is used in other frameworks, then
    # method_name must be implemented separately.
    def method_name
      __name__
    end

    # Expands relative_path relative to method_dir and returns the resulting
    # absolute path.  Raises an error if the resulting path is not relative to
    # method_dir.
    def path(relative_path)
      full_path = File.expand_path(relative_path, method_dir)

      unless full_path.index(method_dir) == 0
        raise "does not make a path relative to method_dir: #{relative_path.inspect}"
      end

      full_path
    end

    # Globs the pattern under method_dir.
    def glob(pattern)
      Dir.glob path(pattern)
    end

    # Creates a directory under method_dir.
    def prepare_dir(relative_path)
      target_dir = path(relative_path)
      unless File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end
      target_dir
    end

    # Same as prepare but does not outdent content.
    def _prepare(relative_path, content=nil, options={}, &block)
      target = path(relative_path)

      if File.exists?(target)
        FileUtils.rm(target)
      else
        target_dir = File.dirname(target)
        FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
      end

      FileUtils.touch(target)
      File.open(target, 'w') {|io| io << content } if content
      File.open(target, 'a', &block) if block

      if mode = options[:mode]
        FileUtils.chmod(mode, target)
      end

      atime = options[:atime]
      mtime = options[:mtime]

      if atime || mtime
        atime  ||= File.atime(target)
        mtime  ||= File.mtime(target)
        File.utime(atime, mtime, target)
      end

      target
    end

    # Creates a file under method_dir with the specified content, which may be
    # provided as a string or with a block (the block recieves an open File).
    # If no content is given, then an empty file is created.
    #
    # Content provided as a string is outdented (see StringMethods#outdent),
    # so this syntax is possible:
    #
    #   path = prepare 'file', %{
    #     line one
    #     line two
    #   }
    #   File.read(path)  # => "line one\nline two\n"
    #
    # Returns the absolute path to the new file.
    def prepare(relative_path, content=nil, options={}, &block)
      content = outdent(content) if content
      _prepare(relative_path, content, options, &block)
    end

    # Returns the content of the file under method_dir, if it exists.
    def content(relative_path, length=nil, offset=nil)
      full_path = path(relative_path)
      File.exists?(full_path) ? File.read(full_path, length, offset) : nil
    end

    # Returns the formatted string mode (ex '100640') of the file under
    # method_dir, if it exists.
    def mode(relative_path)
      full_path = path(relative_path)
      File.exists?(full_path) ? sprintf("%o", File.stat(full_path).mode) : nil
    end

    # Returns the atime for the file under method_dir, if it exists.
    def atime(relative_path)
      full_path = path(relative_path)
      File.exists?(full_path) ? File.atime(full_path) : nil
    end

    # Returns the ctime for the file under method_dir, if it exists.
    def ctime(relative_path)
      full_path = path(relative_path)
      File.exists?(full_path) ? File.ctime(full_path) : nil
    end

    # Returns the mtime for the file under method_dir, if it exists.
    def mtime(relative_path)
      full_path = path(relative_path)
      File.exists?(full_path) ? File.mtime(full_path) : nil
    end

    # Removes a file or directory under method_dir, if it exists.
    def remove(relative_path)
      full_path = path(relative_path)
      FileUtils.rm_r(full_path) if File.exists?(full_path)
    end

    # Recursively removes paths specified for cleanup by paths_to_cleanup.
    def cleanup
      if paths = self.class.paths_to_cleanup[method_name.to_sym]
        paths.each {|path| remove(path) }
      end
    end
  end
end
