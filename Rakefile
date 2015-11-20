require 'rubygems' # must be before everything else
require 'ci/reporter/rake/rspec'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rspec/core/rake_task'

task :default do
  sh "rake -s -T"
end

desc "Clean up build directories"
task :clean do
  sh "rm -rf build"
end

desc "Make build directories"
task :setup do
  sh "mkdir build"
end

desc "Create Debian package"
task :package do
  version = "1.0.#{ENV['BUILD_NUMBER']}"

  sh 'rm -rf build/package'
  sh 'mkdir -p build/package/usr/local/lib/site_ruby/timgroup/'
  sh 'cp -r lib/* build/package/usr/local/lib/site_ruby/timgroup/'

  sh 'mkdir -p build/package/usr/local/bin/'
  sh 'cp -r bin/* build/package/usr/local/bin/'

  arguments = [
    '--description', 'orchestration tool',
    '--url', 'https://github.com/tim-group/orc',
    '-p', "build/orc-transition_#{version}.deb",
    '-n', 'orc-transition',
    '-v', "#{version}",
    '-m', 'Infrastructure <infra@timgroup.com>',
    '-d', 'ruby-bundle',
    '-a', 'all',
    '-t', 'deb',
    '-s', 'dir',
    '-C', 'build/package',
    '--deb-no-default-config-files'
  ]

  argv = arguments.map { |x| "'#{x}'" }.join(' ')
  sh 'rm -f build/*.deb'
  sh "fpm #{argv}"
end

desc "Build and install"
task :install => [:package] do
  sh "sudo dpkg -i build/orc*.deb"
end

desc "Run specs"
if ENV['ORC_RSPEC_SEPARATE'] # run each rspec in a separate ruby instance
  require './spec/rake_override'
  SingleTestFilePerInterpreterSpec::RakeTask.new(:spec => ["ci:setup:rspec"])
else # fast run (common ruby process for all tests)
  RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"])
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

desc 'Generate CTags'
task :ctags do
  sh 'ctags -R --exclude=.git --exclude=build .'
end

desc "Run lint (Rubocop)"
task :lint do
  sh "rubocop"
end
