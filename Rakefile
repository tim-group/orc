require 'rubygems'
require 'rake'
require 'rake/testtask'
begin # Ruby 1.8 vs 1.9 fuckery
  require 'rake/rdoctask'
rescue Exception
  require 'rdoc/task'
end
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
  FileUtils.rmtree("build" )
  FileUtils.rmtree("config")
  if (File.exists?("app_under_test.properties"))
    FileUtils.rm("app_under_test.properties")
  end
end

desc "Make build directories"
task :setup do
  FileUtils.makedirs("build")
end

desc "Create Debian package"
task :package do
  require 'fpm'
  require 'fpm/program'

  FileUtils.mkdir_p("build/package/opt/orctool/")
  FileUtils.cp_r("lib", "build/package/opt/orctool/")
  FileUtils.cp_r("bin", "build/package/opt/orctool/")

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
task :build  => [:setup,:spec,:package]

task :pre_doc do
  sh "if [ -d html ]; then rm -r html; fi"
end

Rake::RDocTask.new do |rd|
    rd.rdoc_files.include("lib/**/*.rb")
end

desc "Build docs"
task :docs do
  sh "stat=$(git status 2> /dev/null | tail -n1); if [ \"nothing to commit (working directory clean)\" != \"$stat\" ]; then echo \"Unclean - please commit before docs\"; exit 2; fi"
  sh "git read-tree --prefix=gh-pages/ -u gh-pages"
  sh "cp -r html/* gh-pages/rdoc"
  sh "rm -r html"
  sh "cat gh-pages/index.md.head README.md > gh-pages/index.md"
  sh "git add -f gh-pages"
  sh "tree=$(git write-tree --prefix=gh-pages/) && commit=$(echo \"Generated docs\" | git commit-tree $tree -p gh-pages) && git update-ref refs/heads/gh-pages $commit && git reset HEAD"
  sh "if [ -d html ]; then rm -r html; fi"
  sh "if [ -d gh-pages ]; then rm -r gh-pages; fi"
end
task :docs => [:pre_doc, :rdoc]
