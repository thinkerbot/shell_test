require 'rake'
require 'rubygems/package_task'

#
# Gem specification
#

def gemspec
  @gemspec ||= begin
    path = File.expand_path('../shell_test.gemspec', __FILE__)
    eval(File.read(path), TOPLEVEL_BINDING, path)
  end
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Prints the gemspec manifest.'
task :print_manifest do
  # collect files from the gemspec, labeling 
  # with true or false corresponding to the
  # file existing or not
  files = gemspec.files.inject({}) do |files, file|
    files[File.expand_path(file)] = [File.exists?(file), file]
    files
  end

  # gather non-rdoc/pkg files for the project
  # and add to the files list if they are not
  # included already (marking by the absence
  # of a label)
  Dir.glob('**/*').each do |file|
    next if file =~ /^(rdoc|pkg|coverage|test)/ || File.directory?(file)
    next if File.extname(file) == '.rbc'

    path = File.expand_path(file)
    files[path] = ['', file] unless files.has_key?(path)
  end

  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts '%-5s %s' % entry
  end
end

#
# Documentation tasks
#

desc 'Generate documentation.'
task :rdoc do
  spec  = gemspec
  files =  spec.files.select {|file| File.extname(file) == '.rb' }
  files += spec.extra_rdoc_files
  options = spec.rdoc_options.join(' ')
  
  Dir.chdir File.expand_path('..', __FILE__) do
    FileUtils.rm_r('rdoc') if File.exists?('rdoc')
    sh "rdoc -o rdoc #{options} '#{files.join("' '")}'"
  end
end

#
# Test tasks
#

def current_ruby
  `ruby -v`.split[0,2].join('-')
end

desc 'Default: Run tests.'
task :default => :test

desc 'Run the tests'
task :test do
  puts "Using #{current_ruby}"

  tests = Dir.glob('test/**/*_test.rb')
  tests.delete_if {|test| test =~ /_test\/test_/ }

  if ENV['RCOV'] == 'true'
    FileUtils.rm_rf File.expand_path('../coverage', __FILE__)
    sh('rcov', '-w', '-Ilib', '--text-report', '--exclude', '^/', *tests)
  else
    sh('ruby', '-w', '-Ilib', '-e', 'ARGV.dup.each {|test| load test}', *tests)
  end
end

desc 'Run the tests many times for stability check'
task :test_n, :n do |task, args|
  tests = Dir.glob('test/**/*_test.rb')
  tests.delete_if {|test| test =~ /_test\/test_/ }

  n = args.n || 100
  fails = 0
  n.times do
    output = `ruby -w -Ilib -e 'ARGV.dup.each {|test| load test}' '#{tests.join("' '")}'`
    output =~ /Started(.*?)Finished/m
    progress = $1.strip
    puts "%-8d%s" % [$?.pid, progress]

    if progress =~ /[F|E]/
      fails += 1 
      $stderr.puts output
      $stdout.puts output.scan(/^test_.*$/).join("\n")
    end
  end

  puts
  puts "Pass: #{n - fails} Fails: #{fails}"
end

desc 'Run the cc tests'
task :cc => :test

desc 'Run rcov'
task :rcov do
  ENV['RCOV'] = 'true'
  Rake::Task["test"].invoke
end
