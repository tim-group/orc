require 'cmdb/namespace'
require 'git'
require 'logger'

class CMDB::Git
  def initialize(options={})
    @repo_url = options[:origin] || 'git@gitit:cmdb'
    @local_path = options[:local_path] || '/opt/orctool/data/cmdb/'
    @branch = options[:branch] || "master"
  end

  def update()
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
  end

  def get_branch()
    return @git.current_branch
  end

  def commit_and_push()
    if File.directory?(@local_path)
      if (@git.status.changed.size>0)
        @git.commit_all('orc auto-updating cmdb')
        @git.fetch( 'origin' )
        @git.merge('origin', 'merge concurrent modifications')
        @git.push()
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end
end
