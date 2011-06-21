# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "shell_test/version"

Gem::Specification.new do |s|
  s.name        = "shell_test"
  s.version     = ShellTest::VERSION
  s.authors     = ["Simon Chiang"]
  s.email       = ["simon.a.chiang@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Test modules for shell scripts}
  s.description = %w{
    Provides test modules to simplify testing of shell scripts and other things
    that require interaction with files. ShellTest is not a testing framework.
    ShellTest integrates with Test::Unit and MiniTest out of the box, but it
    should be possible to include the test modules into other test frameworks.
  }.join(' ')

  s.rubyforge_project = "shell_test"

  s.files         = %w{}
  s.test_files    = %w{}
  s.executables   = %w{}
  s.require_paths = ["lib"]
end
