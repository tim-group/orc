require 'rubygems'
require 'orc/factory'
require 'optparse'
require 'cmdb/git'
require 'client/deploy_client'
require 'client/ansi_status_renderer'
require 'etc'

user = ENV['USER']
ENV['MCOLLECTIVE_SSL_PRIVATE']="/home/#{user}/.mc/#{user}-private.pem"
ENV['MCOLLECTIVE_SSL_PUBLIC']="/etc/mcollective/ssl/clients/#{user}.pem"

module Util
end

class Util::OrcOptionParser
  class PullCmdbRequest
    def required
      return []
    end

    def execute(options)
      CMDB::Git.new().update()
    end
  end

  class StatusRequest
    def required
      return [:environment]
    end

    def execute(options)
      deploy_client = Client::DeployClient.new(options)
      renderer = AnsiStatusRenderer.new()
      statuses = deploy_client.status(options)
      rendered_status = renderer.render(statuses)
      print rendered_status
    end
  end

  class DeployRequest
    def required
      return [:environment,:application,:version]
    end

    def execute(options)
      high_level_orchestration = Orc::Factory.high_level_orchestration(options)
      high_level_orchestration.deploy(options[:version])
    end
  end

  class  PromotionRequest
    def required
      return [:environment,:application,:promote_from_environment]
    end

    def execute(options)
      high_level_orchestration = Orc::Factory.high_level_orchestration(options)
      high_level_orchestration.promote_from_environment(options[:promote_from_environment])
    end
  end

  class  InstallRequest
    def required
      return [:environment,:application,:version]
    end

    def execute(options)
      high_level_orchestration = Orc::Factory.high_level_orchestration(options)
      high_level_orchestration.install(options[:version])
    end
  end

  class  SwapRequest
    def required
      return [:environment,:application]
    end

    def execute(options)
      high_level_orchestration = Orc::Factory.high_level_orchestration(options)
      high_level_orchestration.swap()
    end
  end

  class ResolveRequest
    def required
      return [:environment,:application]
    end

    def execute(options)
      engine = Orc::Factory.engine(options)
      engine.resolve()
    end
  end

  def initialize()
    @options = {}
    @commands = []

    @option_parser = OptionParser.new do|opts|
      opts.banner =
"Usage:
	orc --environment=production --show-status
	orc --environment=production --application=MyApp --resolve
	orc --environment=production --application=MyApp --version=2.21.0 --deploy

"

      opts.on("-e","--environment ENVIRONMENT", "specify the environment to execute the plan") do |env|
        @options[:environment] = env
      end
      opts.on("-f","--promote-from ENVIRONMENT", "specify the environment to promote from") do |env|
        @options[:promote_from_environment] = env
      end
      opts.on("-a","--application APPLICATION", "specify the application to execute the plan for") do |app|
        @options[:application] = app
      end
      opts.on("-v","--version VERSION", "") do    |version|
        @options[:version] = version
      end

      opts.on( '-p', '--pull-cmdb', 'Pulls changes to the CMDB' ) do
        @commands << PullCmdbRequest.new()
      end
      opts.on( '-s', '--show-status', 'Shows status' ) do
        @commands << StatusRequest.new()
      end
      opts.on('-d','--deploy','changes the cmdb - does an install followed by a swap') do
        @commands << DeployRequest.new()
      end
      opts.on('-i','--install','changes the cmdb - states a new version for the inactive group') do
        @commands << InstallRequest.new()
      end
      opts.on('-c','--swap','changes the cmdb, swaps the online group to offline and vice-versa') do
        @commands << DeployRequest.new()
      end
      opts.on( '-r', '--resolve', 'Resolves the differences from the CMDB' ) do
        @commands << ResolveRequest.new()
      end
      opts.on( '-u', '--promote', 'Promotes versions to other environments CMDB' ) do
        @commands << PromotionRequest.new()
      end

    end
  end

  def check_required(required)
    required.each do |option|
      if @options[option].nil?
        print @option_parser.help()
        exit(1)
      end
    end
  end

  def parse
    @option_parser.parse!
    @commands.each do |command|
      check_required(command.required())
    end

    if @commands.size==0
      print @option_parser.help()
      exit(1)
    end

    @commands.each do |command|
      command.execute(@options)
    end
  end
end
