require 'cmdb/namespace'
require 'git'
require 'logger'
require 'orc/util/timeout'

class CMDB::Git
  include Orc::Util::Timeout
  def initialize(options={})
    @repo_url = options[:origin] || 'git@git:cmdb'
    @local_path = options[:local_path] || '/opt/orctool/data/cmdb/'
    @branch = options[:branch] || "master"
    @timeout = options[:timeout] || 10
    @debug = false
  end

  def update()
    if File.directory?(@local_path)
      timeout(@timeout) do
        logger = @debug ? STDOUT : '/dev/null'
        @git = Git.open(@local_path, :log => Logger.new(logger))
        @git.remotes.first.fetch
        @git.fetch( 'origin' )
        @git.merge('origin', 'merge concurrent modifications')
        @git.pull
      end
    else
      timeout(@timeout) do
        @git = Git.clone(@repo_url,@local_path, :log => Logger.new(STDOUT))
      end
    end

    if self.get_branch() != @branch
      timeout(@timeout) do
        @git.branch( @branch ).checkout
      end
    end
  end

  def get_branch()
    return @git.current_branch
  end

  def commit_and_push()
    if File.directory?(@local_path)
      if (@git.status.changed.size>0)
        timeout(@timeout) do
          @git.commit_all('orc auto-updating cmdb')
          @git.fetch( 'origin' )
          @git.merge('origin', 'merge concurrent modifications')
          @git.push()
        end
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end
end

