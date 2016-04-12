require 'git'
require 'logger'
require 'timeout'
require 'orc/cmdb/namespace'

class Orc::CMDB::Git
  def initialize(options = {})
    @repo_url = options[:origin] || raise("Need origin option")
    @local_path = options[:local_path] || raise("Need local_path option")
    @branch = options[:branch] || "master"
    @timeout = options[:timeout] || 60
    @options = options
  end

  def update
    logger = @options[:debug] ? Logger.new(STDOUT) : nil
    if File.directory?(@local_path)
      Timeout::timeout(@timeout) do
        @git = Git.open(@local_path, :log => logger)
        @git.remotes.first.fetch
        @git.fetch('origin')
        @git.merge('origin', 'merge concurrent modifications')
        @git.pull
      end
      Timeout::timeout(@timeout) do
        Dir.chdir(@local_path) do
          system('git gc')
        end
      end
    else
      Timeout::timeout(@timeout) do
        @git = Git.clone(@repo_url, @local_path, :log => logger)
      end
    end

    if get_branch != @branch
      Timeout::timeout(@timeout) do
        @git.branch(@branch).checkout
      end
    end
  end

  def get_branch
    @git.current_branch
  end

  def commit_and_push(message = 'orc auto-updating cmdb')
    if File.directory?(@local_path)
      # XXX line below works around a ruby bug, see https://github.com/schacon/ruby-git/issues/23
      @git.status.changed.each { @git.diff.entries }
      if @git.status.changed.size > 0
        Timeout::timeout(@timeout) do
          @git.commit_all(message)
          push_with_retry
        end
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end

  private

  def push_with_retry
    @git.fetch('origin')
    @git.merge('origin', 'merge concurrent modifications')
    @git.push
  rescue Git::GitExecuteError => _error
    # if (attempt_number + 1 > total_attempts_allowed)
    #   raise error
    # end
    push_with_retry
  end
end
