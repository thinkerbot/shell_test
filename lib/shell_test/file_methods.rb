require 'fileutils'
require 'shell_test/string_methods'

module ShellTest
  module FileMethods
    module ClassMethods
      attr_accessor :class_dir

      attr_reader :cleanup_method_registry

      def cleanup_methods
        @cleanup_methods ||= begin
          cleanup_methods = {}

          ancestors.reverse.each do |ancestor|
            next unless ancestor.kind_of?(ClassMethods)
            ancestor.cleanup_method_registry.each_pair do |key, value|
              if value.nil?
                cleanup_methods.delete(key)
              else
                cleanup_methods[key] = value
              end
            end
          end

          cleanup_methods
        end
      end

      def reset_cleanup_methods
        @cleanup_methods = nil
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

        base.reset_cleanup_methods
        unless base.instance_variable_defined?(:@cleanup_method_registry)
          base.instance_variable_set(:@cleanup_method_registry, {})
        end

        unless base.instance_variable_defined?(:@cleanup_paths)
          base.instance_variable_set(:@cleanup_paths, ['.'])
        end

        unless base.instance_variable_defined?(:@cleanup)
          base.instance_variable_set(:@cleanup, true)
        end
      end

      def inherited(base) # :nodoc:
        ClassMethods.initialize(base)
        super
      end

      def define_method_cleanup(method_name, dirs)
        reset_cleanup_methods
        cleanup_method_registry[method_name.to_sym] = dirs
      end

      def remove_method_cleanup(method_name)
        reset_cleanup_methods
        cleanup_method_registry.delete(method_name.to_sym)
      end

      def undef_method_cleanup(method_name)
        reset_cleanup_methods
        cleanup_method_registry[method_name.to_sym] = nil
      end

      def cleanup_paths(*dirs)
        @cleanup_paths = dirs
      end

      def cleanup(*method_names)
        if method_names.empty?
          @cleanup = true
        else
          method_names.each do |method_name|
            define_method_cleanup method_name, @cleanup_paths
          end
        end
      end

      def no_cleanup(*method_names)
        if method_names.empty?
          @cleanup = false
        else
          method_names.each do |method_name|
            undef_method_cleanup method_name
          end
        end
      end

      def method_added(sym)
        if @cleanup && !cleanup_method_registry.has_key?(sym.to_sym) && sym.to_s[0, 5] == "test_"
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

    # Calls cleanup to remove any files left over from previous test runs (for
    # instance by running with a flag to keep outputs).
    def setup
      super
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

    # Returns the absolute path to the current working directory.
    def user_dir
      @user_dir   ||= File.expand_path('.')
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

    # Shortcut to access the class.cleanup_methods.
    def cleanup_methods
      self.class.cleanup_methods
    end

    # Recursively removes paths specified for cleanup in cleanup_methods.
    def cleanup
      if cleanup_paths = cleanup_methods[method_name.to_sym]
        cleanup_paths.each {|relative_path| remove(relative_path) }
      end
    end

    # Expands relative_path relative to method_dir and returns the resulting
    # absolute path.  Raises an error if the resulting path is not relative to
    # method_dir.
    def path(relative_path)
      path = File.expand_path(relative_path, method_dir)

      unless path.index(method_dir) == 0
        raise "does not make a path relative to method_dir: #{relative_path.inspect}"
      end

      path
    end

    # Same as prepare but does not outdent content.
    def _prepare(relative_path, content=nil, &block)
      target = path(relative_path)

      if File.exists?(target)
        FileUtils.rm(target)
      else
        target_dir = File.dirname(target)
        FileUtils.mkdir_p(target_dir)
      end

      FileUtils.touch(target)
      File.open(target, 'w') {|io| io << content } if content
      File.open(target, 'a', &block) if block

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
    def prepare(relative_path, content=nil, &block)
      content = outdent(content) if content
      _prepare(relative_path, content, &block)
    end

    # Removes a file or directory under method_dir, if it exists.
    def remove(relative_path)
      full_path = path(relative_path)
      FileUtils.rm_r(full_path) if File.exists?(full_path)
    end
  end
end
