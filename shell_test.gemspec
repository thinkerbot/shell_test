# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'shell_test/version'

Gem::Specification.new do |s|
  s.name        = 'shell_test'
  s.version     = ShellTest::VERSION
  s.authors     = ['Simon Chiang']
  s.email       = ['simon.a.chiang@gmail.com']
  s.homepage    = ''
  s.summary     = %q{Test modules for shell scripts}
  s.description = %w{
    Provides test modules to simplify testing of shell scripts.
    
    ShellTest is not a testing framework. ShellTest integrates with Test::Unit and
    MiniTest out of the box, but it should be possible to include the test modules
    into other test frameworks.
  }.join(' ')

  s.rubyforge_project = 'shell_test'

  s.extra_rdoc_files = %w{
    README.rdoc
    MIT-LICENSE
  }

  s.files         = %w{
    lib/shell_test.rb
    lib/shell_test/command_parser.rb
    lib/shell_test/file_methods.rb
    lib/shell_test/regexp_escape.rb
    lib/shell_test/shell_methods.rb
    lib/shell_test/unit.rb
    lib/shell_test/unit/shim.rb
    lib/shell_test/version.rb
  }
  s.test_files    = %w{}
  s.executables   = %w{}
  s.require_paths = ['lib']
end
