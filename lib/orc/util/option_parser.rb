require 'rubygems'
require 'orc/util/namespace'
require 'orc/factory'
require 'optparse'
require 'orc/cmdb/git'
require 'orc/live/deploy_client'
require 'orc/util/ansi_status_renderer'
require 'etc'

user = ENV['USER']
ENV['MCOLLECTIVE_SSL_PRIVATE'] = "/home/#{user}/.mc/#{user}-private.pem" unless ENV.has_key?('MCOLLECTIVE_SSL_PRIVATE')
ENV['MCOLLECTIVE_SSL_PUBLIC'] = "/etc/mcollective/ssl/clients/#{user}.pem" unless ENV.has_key?('MCOLLECTIVE_SSL_PUBLIC')

class Orc::Util::OptionParser
  def initialize
    $options = {}
    @commands = []

    @option_parser = OptionParser.new do |opts|
      opts.banner =
        "Usage:\n" \
        "  orc --environment=production --status\n" \
        "  orc --environment=production --status --group=blue\n" \
        "  orc --environment=production --application=MyApp --resolve\n" \
        "  orc --environment=production --application=MyApp --version=2.21.0 --deploy\n" \
        "  orc --environment=production --application=MyApp --version=2.21.0 --group=blue --deploy\n"

      opts.on('-D', '--debug', 'enable debug mode') do
        $options[:debug] = true
      end
      opts.on("-e", "--environment ENVIRONMENT", "specify the environment to execute the plan") do |env|
        $options[:environment] = env
      end
      opts.on("-f", "--promote-from ENVIRONMENT", "specify the environment to promote from") do |env|
        $options[:promote_from_environment] = env
      end
      opts.on("-a", "--application APPLICATION", "specify the application to execute the plan for") do |app|
        $options[:application] = app
      end
      opts.on("-v", "--version VERSION", "") do |version|
        $options[:version] = version
      end
      opts.on("-g", "--group GROUP", "specify the group to execute the plan") do |env|
        $options[:group] = env
      end

      [StatusRequest, DeployRequest, InstallRequest, LimitedInstallRequest, SwapRequest, ResolveRequest,
       PromotionRequest, RollingRestartRequest, NeedsStepsToResolve
      ].
      each do |req|
        req.setup_command_options($options, opts, @commands)
      end
    end
  end

  def parse
    begin
      @option_parser.parse! argv
    rescue Exception => e
      puts "Option validation failed: #{e}"
      puts e.backtrace.inspect
      puts @option_parser.help
      exit(1)
    end

    @commands.each do |command|
      check_required(command)
    end

    if @commands.size == 0
      print @option_parser.help
      exit(1)
    end
    self
  end

  def execute
    @commands.each do |command|
      command.execute(Orc::Factory.new($options))
    end
  end

  private

  # XXX
  def argv
    ARGV
  end

  def check_required(command)
    required = command.required
    failed = []
    required.each do |option|
      failed.push(option) if $options[option].nil?
    end
    if failed.size > 0
      print "Command #{command.long_command_name} required the following options (not supplied):\n"
      print failed.map { |n| "  --#{n}" }.join("\n")
      print "\n\n"
      print @option_parser.help
      exit(1)
    end
  end

  class Base
    attr_reader :options
    def self.setup_command_options(options, opts, commands)
      opts.on(*command_options) do
        commands << new(options)
      end
    end

    def initialize(options)
      @options = options
    end

    def long_command_name
      self.class.command_options[1] # FIXME: Array index is horrible!
    end
  end

  class StatusRequest < Base
    def required
      [:environment]
    end

    def execute(factory)
      deploy_client = factory.remote_client
      renderer = Orc::Util::AnsiStatusRenderer.new
      statuses = deploy_client.status
      rendered_status = renderer.render(statuses)
      print rendered_status
    end

    def self.command_options
      ['-s', '--status', 'shows status']
    end
  end

  class DeployRequest < Base
    def required
      [:environment, :application, :version]
    end

    def execute(factory)
      if options[:group].nil?
        factory.high_level_orchestration.deploy(options[:version])
      else
        factory.high_level_orchestration.deploy(options[:version], options[:group])
      end
    end

    def self.command_options
      ['-d', '--deploy', 'changes the cmdb - does an install followed by a swap']
    end
  end

  class PromotionRequest < Base
    def required
      [:environment, :application, :promote_from_environment]
    end

    def execute(factory)
      factory.high_level_orchestration.promote_from_environment(options[:promote_from_environment])
    end

    def self.command_options
      ['-u', '--promote', 'promotes versions to other environments CMDB']
    end
  end

  class InstallRequest < Base
    def required
      [:environment, :application, :version]
    end

    def execute(factory)
      if options[:group].nil?
        factory.high_level_orchestration.install(options[:version])
      else
        factory.high_level_orchestration.install(options[:version], options[:group])
      end
    end

    def self.command_options
      ['-i', '--install', 'changes the cmdb - states a new version for the inactive group']
    end
  end

  class LimitedInstallRequest < Base
    def required
      [:environment, :application, :version]
    end

    def execute(factory)
      factory.high_level_orchestration.limited_install(options[:version])
    end

    def self.command_options
      ['-l', '--limited-install', 'changes the cmdb - states a new version for a single group']
    end
  end

  class SwapRequest < Base
    def required
      [:environment, :application]
    end

    def execute(factory)
      factory.high_level_orchestration.swap
    end

    def self.command_options
      ['-c', '--swap', 'changes the cmdb, swaps the online group to offline and vice-versa']
    end
  end

  class ResolveRequest < Base
    def required
      [:environment, :application]
    end

    def execute(factory)
      factory.cmdb_git.update
      factory.engine.resolve
    end

    def self.command_options
      ['-r', '--resolve', 'resolves the differences from the CMDB']
    end
  end

  class RollingRestartRequest < Base
    def required
      [:environment, :application]
    end

    def execute(factory)
      factory.cmdb_git.update
      factory.engine.check_rolling_restart_possible
      factory.restart_engine.resolve
    end

    def self.command_options
      ['-R', '--rolling-restart', 'safely restarts a group of applications']
    end
  end

  class NeedsStepsToResolve < Base
    def required
      [:environment, :application]
    end

    def execute(factory)
      factory.cmdb_git.update
      required_resolutions = factory.engine(:quiet => !@options[:debug]).required_resolutions

      puts required_resolutions.size
    end

    def self.command_options
      ['-n', '--needs-steps-to-resolve', 'outputs estimated number of steps required to resolve differences from CMDB']
    end
  end
end
