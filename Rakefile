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
  sh "mkdir -p build/omnibus/bin"
  sh "mkdir -p build/omnibus/lib/ruby/site_ruby"
  sh "mkdir -p build/omnibus/embedded/lib/ruby/site_ruby"

  sh "cp -r bin/* build/omnibus/bin/"
  sh "cp -r lib/* build/omnibus/embedded/lib/ruby/site_ruby"
  # expose orcs libs; stackbuilder depends on orc/util/option_parser.rb
  sh "ln -s ../../../embedded/lib/ruby/site_ruby/orc build/omnibus/lib/ruby/site_ruby/orc"
end

# depends on ruby-bundler
desc "Create an omnibus .deb package"
task :omnibus_deb do
  sh "rm -rf /tmp/omnibus_orc"

  sh "mkdir -p /tmp/omnibus_orc"

  sh "sudo apt-get install ruby-bundler"
  sh "git clone http://git/git/github/chef/omnibus-software.git /tmp/omnibus_orc/omnibus-software"
  sh "git clone http://git/git/github/tim-group/omnibus-timgroup.git /tmp/omnibus_orc/omnibus-timgroup"

  sh "cd /tmp/omnibus_orc/omnibus-timgroup/ && bundle install"
  sh "cd /tmp/omnibus_orc/omnibus-timgroup/ && ./bin/omnibus build orc"

  #sh "rm -rf /tmp/omnibus_orc"
end


desc "Create Debian package"
task :package do
  sh "mkdir -p build/package/opt/orctool/"
  sh "cp -r lib build/package/opt/orctool/"
  sh "cp -r bin build/package/opt/orctool/"
  sh "mkdir -p build/package/usr/bin/"
  sh "ln -sf /opt/orctool/bin/orc build/package/usr/bin/orc"

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

  argv = arguments.map { |x| "'#{x}'" }.join(' ')
  sh "rm -f build/orctool_*.deb"
  sh "fpm #{argv}"
end

desc "Build and install"
task :install => [:package] do
  sh "sudo dpkg -i build/orctool*.deb"
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

desc "Run lint (Rubocop)"
task :lint do
  sh "/var/lib/gems/1.9.1/bin/rubocop --require rubocop/formatter/checkstyle_formatter --format " \
     "RuboCop::Formatter::CheckstyleFormatter --out tmp/checkstyle.xml"
end
