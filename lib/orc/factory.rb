require 'orc/namespace'
require 'orc/model/application'
require 'orc/mismatch_resolver'
require 'client/deploy_client'
require 'cmdb/yaml'
require 'cmdb/git'
require 'cmdb/high_level_orchestration'
require 'progress/log'

class Orc::Factory
  def self.cmdb
    CMDB::Yaml.new( :data_dir => "/opt/orctool/data/cmdb/")
  end

  def self.remote_client(options)
    Client::DeployClient.new(
      :environment => options[:environment],
      :application => options[:application]
    )
  end

  def self.high_level_orchestration(options)
    options[:cmdb] = self.cmdb
    options[:git] = CMDB::Git.new()
    CMDB::HighLevelOrchrestration.new(options)
  end

  def self.engine(options)
    remote_client = self.remote_client(options)
    mismatch_resolver = Orc::MismatchResolver.new(remote_client)
    logger = Progress.logger()
    app_model = Orc::Model::Application.new(
      :remote_client      => remote_client,
      :cmdb               => self.cmdb,
      :environment        => options[:environment],
      :application        => options[:application],
      :progress_logger    => progress_logger,
      :mismatch_resolver  => mismatch_resolver
    )

    Orc::Engine.new(
      :application_model => app_model,
      :log               => logger
    )
  end
end

