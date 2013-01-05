require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'fileutils'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

class Project
  def initialize args
    @name = args[:name]
    @description = args[:description]
    @version = args[:version]
  end

  def name
    return @name
  end

  def description
    return @description
  end

  def version
    return @version
  end
end

@project = Project.new(
  :name=>"orctool",
  :description=>"orchestration tool",
  :version=>"1.0.#{ENV['BUILD_NUMBER']}"
)

task :default do
  sh "rake -s -T"
end

desc "Create gem"
task :gem do
  sh "if [ -f *.gem ]; then rm *.gem; fi"
  sh "gem build orc.gemspec"
end

desc "Create debian package from gem"
task :gemdeb do
  sh "if [ -f *.deb ]; then rm *.deb; fi"
  sh "/var/lib/gems/1.8/bin/fpm -s gem -t deb orc-*.gem"
end
task :gemdeb => [:gem]

desc "Remove build directory, etc."
task :clean do
  FileUtils.rmtree( "build"  )
  FileUtils.rmtree( "config" )
  if ( File.exists?("app_under_test.properties") )
    FileUtils.rm( "app_under_test.properties" )
  end
end

desc "Make build directories"
task :setup do
  FileUtils.makedirs( "build" )
end

desc "Create Debian package"
task :package do
  require 'fpm'
  require 'fpm/program'

  FileUtils.mkdir_p( "build/package/opt/orctool/" )
  FileUtils.cp_r( "lib", "build/package/opt/orctool/" )
  FileUtils.cp_r( "bin", "build/package/opt/orctool/" )

  arguments = [
    "-p", "build/#{@project.name}.deb" ,
    "-n" ,"#{@project.name}" ,
    "-v" ,"#{@project.version}" ,
    "-m" ,"Infrastructure <infra@timgroup.com>" ,
    "-a", 'all' ,
    "-t", 'deb' ,
    "-s", 'dir' ,
    "--description", "#{@project.description}" ,
    "--url", 'https://github.com/youdevise/orc',
    "-C" ,'build/package'
  ]

  raise "problem creating debian package " unless FPM::Program.new.run(arguments)==0
end

task :test => [:setup]
Rake::TestTask.new { |t|
  t.pattern = 'test/**/*_test.rb'
}

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"]) do |t|
  t.rspec_opts = %w[--color]
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

desc "Setup, package, test, and upload"
task :build  => [:setup,:package,:test]
