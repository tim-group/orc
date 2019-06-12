require 'git'
require 'logger'
require 'timeout'
require 'orc/cmdb/namespace'

# XXX Monkey patch ruby-git until https://github.com/ruby-git/ruby-git/pull/320 is fixed
module Git
  class Lib
    ls_files_orig = instance_method(:ls_files)
    define_method(:ls_files) { |location = '.'| ls_files_orig.bind(self).call(location) }
  end
end

class Orc::CMDB::Git
  attr_accessor :local_path

  def initialize(options = {})
    @repo_url = options[:origin] || raise("Need origin option")
    @local_path = options[:local_path] || raise("Need local_path option")
    @branch = options[:branch] || "master"
    @timeout = options[:timeout] || 60
    @depth = options[:depth] || 1000
    @options = options
    @logger = choose_logger(options)
  end

  def update
    if File.directory?(@local_path)
      Timeout::timeout(@timeout) do
        @git = Git.open(@local_path, :log => @logger)
        @git.remotes.first.fetch
        @git.fetch('origin')
        @git.merge('origin', 'merge concurrent modifications')
        @git.pull
      end
      Timeout::timeout(@timeout) do
        Dir.chdir(@local_path) do
          gc_cmd = 'git gc' + (@options[:debug] ? '' : ' --quiet')
          system(gc_cmd)
        end
      end
    else
      Timeout::timeout(@timeout) do
        @git = Git.clone(@repo_url, @local_path, :log => @logger, :depth => @depth)
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
          push_with_retry(0, 5)
        end
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end

  private

  def choose_logger(options)
    options[:logger] || Logger.new(STDOUT) if options[:debug]
  end

  def push_with_retry(attempt_number, total_attempts_allowed)
    @git.fetch('origin')
    @git.merge('origin', 'merge concurrent modifications')
    @git.push
  rescue Git::GitExecuteError => error
    raise error if attempt_number > total_attempts_allowed
    if @options[:debug]
      @logger.log("Push to cmdb failed. Retrying (#{attempt_number}/#{total_attempts_allowed})")
    end
    push_with_retry(attempt_number + 1, total_attempts_allowed)
  end
end
