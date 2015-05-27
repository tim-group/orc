require 'rubygems' # must be before everything else
require 'ci/reporter/rake/rspec'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rspec/core/rake_task'

class Project
  attr_reader :name
  attr_reader :description
  attr_reader :version

  def initialize(args)
    @name = args[:name]
    @description = args[:description]
    @version = args[:version]
  end
end

@project = Project.new(
  :name        => "orctool",
  :description => "orchestration tool",
  :version     => "1.0.#{ENV['BUILD_NUMBER']}"
)

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

desc "Prepare a directory tree for omnibus"
task :omnibus do
  sh "rm -rf build/omnibus"

  sh "mkdir -p build/omnibus"
  sh "mkdir -p build/omnibus/embedded"
  sh "cp -r bin build/omnibus/"
  sh "cp -r lib build/omnibus/embedded/lib/"
end

desc "Create Debian package"
task :package do
  require 'fpm'
  require 'fpm/program'

  sh "mkdir -p build/package/opt/orctool/"
  sh "cp -r lib build/package/opt/orctool/"
  sh "cp -r bin build/package/opt/orctool/"

  arguments = [
    "-p", "build/#{@project.name}_#{@project.version}.deb",
    "-n", "#{@project.name}",
    "-v", "#{@project.version}",
    "-m", "Infrastructure <infra@timgroup.com>",
    "-a", 'all',
    "-t", 'deb',
    "-s", 'dir',
    "--description", "#{@project.description}",
    "--url", 'https://github.com/tim-group/orc',
    "-C", 'build/package'
  ]

  raise "problem creating debian package " unless FPM::Program.new.run(arguments) == 0
end

desc "Build and install"
task :install => [:package] do
  sh "sudo dpkg -i build/orctool*.deb"
end

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"]) do |t|
  t.rspec_opts = %w(--color --require=spec_requires --require=spec_helper)
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

desc "Run lint (Rubocop)"
task :lint do
  sh "/var/lib/gems/1.9.1/bin/rubocop --require rubocop/formatter/checkstyle_formatter --format " \
     "RuboCop::Formatter::CheckstyleFormatter --out tmp/checkstyle.xml"
end
