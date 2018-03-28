require 'orc/namespace'
require 'orc/config'
require 'orc/model/builder'
require 'orc/engine/engine'
require 'orc/engine/mismatch_resolver'
require 'orc/engine/restart_resolver'
require 'orc/live/deploy_client'
require 'orc/cmdb/yaml'
require 'orc/cmdb/git'
require 'orc/cmdb/high_level_orchestration'
require 'orc/util/progress_reporter'

class Orc::Factory
  attr_reader :application, :environment, :group

  attr_accessor :cmdb

  def initialize(options = {}, dependencies = {})
    @application = options[:application]
    @environment = options[:environment]
    @group = options[:group]

    @timeout = options[:timeout]
    @cmdb = dependencies[:cmdb]
    @remote_client = dependencies[:remote_client]
    @debug = options[:debug]
  end

  def config
    @config ||= Orc::Config.new
  end

  def cmdb
    @cmdb ||= Orc::CMDB::Yaml.new(:data_dir => config['cmdb_local_path'])
  end

  def remote_client
    @remote_client ||= Orc::DeployClient.new(
      :environment => environment,
      :application => application,
      :group       => group
    )
  end

  def cmdb_git
    @cmdb_git ||= Orc::CMDB::Git.new(
      :origin     => config['cmdb_repo_url'],
      :local_path => config['cmdb_local_path'],
      :debug      => @debug
    )
  end

  def high_level_orchestration
    @high_level_orchestration ||= Orc::CMDB::HighLevelOrchestration.new(
      :cmdb => cmdb,
      :git => cmdb_git,
      :environment => environment,
      :application => application
    )
  end

  def restart_engine
    resolver = Orc::Engine::RestartResolver.new(remote_client, @timeout)
    engine_for_resolver(resolver, :quiet => false)
  end

  def engine(quiet = false)
    mismatch_resolver = Orc::Engine::MismatchResolver.new(remote_client, @timeout)
    engine_for_resolver(mismatch_resolver, quiet)
  end

  private

  def engine_for_resolver(resolver, quiet)
    logger = quiet ? Orc::Util::ProgressReporter.null_logger : Orc::Util::ProgressReporter.logger
    model_generator = Orc::Model::Builder.new(
      :remote_client      => remote_client,
      :cmdb               => cmdb,
      :environment        => environment,
      :application        => application,
      :progress_logger    => logger,
      :mismatch_resolver  => resolver
    )

    Orc::Engine::Engine.new(
      :model_generator   => model_generator,
      :log               => logger
    )
  end
end
