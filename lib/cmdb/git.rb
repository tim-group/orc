require 'cmdb/namespace'
require 'git'
require 'logger'
require 'orc/util/timeout'

class CMDB::Git
  include Orc::Util::Timeout
  def initialize(options={})
    @repo_url = options[:origin] || raise("Need origin option")
    @local_path = options[:local_path] || raise("Need local_path option")
    @branch = options[:branch] || "master"
    @timeout = options[:timeout] || 10
    @debug = false
  end

  def update()
    logger = @debug ? Logger.new(STDOUT) : nil
    if File.directory?(@local_path)
      timeout(@timeout) do
        @git = Git.open(@local_path, :log => logger)
        @git.remotes.first.fetch
        @git.fetch( 'origin' )
        @git.merge('origin', 'merge concurrent modifications')
        @git.pull
      end
    else
      timeout(@timeout) do
        @git = Git.clone(@repo_url, @local_path, :log => logger)
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

