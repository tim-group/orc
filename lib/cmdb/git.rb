require 'cmdb/namespace'
require 'git'
require 'logger'

require 'dl/import'
module Alarm
  begin
    extend DL::Importable
  rescue # For ruby >= 1.9
    extend DL::Importer
  end
  if RUBY_PLATFORM =~ /darwin/
    so_ext = 'dylib'
  else
    so_ext = 'so.6'
  end
  dlload "libc.#{so_ext}"
  extern "unsigned int alarm(unsigned int)"
end

class CMDB::Git
  def initialize(options={})
    @repo_url = options[:origin] || 'git@git:cmdb'
    @local_path = options[:local_path] || '/opt/orctool/data/cmdb/'
    @branch = options[:branch] || "master"
    @timeout = 10
  end

  def update()
    Alarm.alarm(@timeout)
    if File.directory?(@local_path)
      @git = Git.open(@local_path, :log => Logger.new(STDOUT))
      @git.remotes.first.fetch
      @git.fetch( 'origin' )
      @git.merge('origin', 'merge concurrent modifications')
      @git.pull
    else
      @git = Git.clone(@repo_url,@local_path, :log => Logger.new(STDOUT))
    end

    if self.get_branch() != @branch
      @git.branch( @branch ).checkout
    end
    Alarm.alarm(0)
  end

  def get_branch()
    return @git.current_branch
  end

  def commit_and_push()
    if File.directory?(@local_path)
      if (@git.status.changed.size>0)
        Alarm.alarm(@timeout)
        @git.commit_all('orc auto-updating cmdb')
        @git.fetch( 'origin' )
        @git.merge('origin', 'merge concurrent modifications')
        @git.push()
        Alarm.alarm(0)
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end
end

