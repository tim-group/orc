require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'fileutils'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

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
  :name => "orctool",
  :description => "orchestration tool",
  :version => "1.0.#{ENV['BUILD_NUMBER']}"
)

task :default do
  sh "rake -s -T"
end

desc "Create gem"
task :gem do
  sh "rm -f *.gem"
  sh "gem build orc.gemspec"
end

desc "Create debian package from gem"
task :gemdeb do
  sh "rm -f *.deb"
  sh "/var/lib/gems/1.8/bin/fpm -s gem -t deb orc-*.gem"
end
task :gemdeb => [:gem]

desc "Remove build directory, etc."
task :clean do
  FileUtils.rmtree("build")
  FileUtils.rmtree("config")
  if File.exist?("app_under_test.properties")
    FileUtils.rm("app_under_test.properties")
  end
end

desc "Make build directories"
task :setup do
  FileUtils.makedirs("build")
end

desc "Create a directory tree for omnibus"
task :omnibus do
  sh "rm -rf build/omnibus"
  sh "mkdir -p build/omnibus"
  sh "tar xmOf orc-*.gem data.tar.gz | tar xmzC build/omnibus"
end
task :omnibus => [:gem]

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

desc "Test and package"
task :build => [:spec, :package]

desc "Build and install"
task :install => [:package] do
  sh "sudo dpkg -i build/orctool*.deb"
end

task :pre_doc do
  sh "rm -rf html"
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
end

desc "Build docs"
task :docs do
  sh "stat=$(git status 2> /dev/null | tail -n1); " \
     "if [ \"nothing to commit (working directory clean)\" != \"$stat\" ]; then " \
     "echo \"Unclean - please commit before docs\"; exit 2; fi"
  sh "git read-tree --prefix=gh-pages/ -u gh-pages"
  sh "mv html/* gh-pages/rdoc"
  sh "rm -r html"
  sh "cat gh-pages/index.md.head README.md > gh-pages/index.md"
  sh "git add -f gh-pages"
  sh "tree=$(git write-tree --prefix=gh-pages/) && " \
     "commit=$(echo \"Generated docs\" | git commit-tree $tree -p gh-pages) && " \
     "git update-ref refs/heads/gh-pages $commit && git reset HEAD"
  sh "rm -rf html"
  sh "rm -rf gh-pages"
end
task :docs => [:pre_doc, :rdoc]

desc "Run lint (Rubocop)"
task :lint do
  sh "/var/lib/gems/1.9.1/bin/rubocop --require rubocop/formatter/checkstyle_formatter --format " \
     "RuboCop::Formatter::CheckstyleFormatter --out tmp/checkstyle.xml"
end
