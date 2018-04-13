require 'orc/model/namespace'
require 'orc/model/application'
require 'orc/model/group'
require 'orc/model/instance'

class Orc::Model::Builder
  def initialize(args)
    @remote_client = args[:remote_client] # || raise('Nust pass :remote_client')
    @cmdb = args[:cmdb]
    @environment = args[:environment] # || raise('Must pass :environment')
    @application = args[:application] # || raise('Must pass :application')
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass :mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass :progress_logger')
  end

  def get_cmdb_groups
    cmdb_model_for_app = @cmdb.retrieve_application(:environment => @environment, :application => @application)
    raise Orc::CMDB::ApplicationMissing.new("#{@application} not found in CMDB for environment:#{@environment}") \
      if cmdb_model_for_app.nil?
    groups = {}
    cmdb_model_for_app.each do |group|
      groups[group[:name]] = Orc::Model::Group.new(group)
    end
    groups
  end

  def create_live_model(session)
    @progress_logger.log("creating live model")

    session[:instance_data] = {} if session[:instance_data].nil?
    session[:cleaning_instance_keys] = Set[] if session[:cleaning_instance_keys].nil?
    session[:provisioning_instance_keys] = Set[] if session[:provisioning_instance_keys].nil?

    missing_instance_keys = Set[] | session[:cleaning_instance_keys] | session[:provisioning_instance_keys]

    groups = get_cmdb_groups
    statuses = @remote_client.status(
      { :application => @application, :environment => @environment },
      missing_instance_keys.map { |key| key[:host] })

    instances = statuses.map do |instance_data|
      group = groups[instance_data[:group]]
      raise Orc::Model::GroupMissing.new("#{instance_data[:group]}") if group.nil?
      instance = Orc::Model::Instance.new(instance_data, group, session)
      session[:instance_data][instance.key] = instance_data
      instance
    end

    missing_instance_keys.subtract(instances.map(&:key))
    instances += missing_instance_keys.map do |key|
      instance_data = session[:instance_data][key].clone
      instance_data[:participating] = false
      instance_data[:missing] = true
      instance_data[:health] = 'ill'
      Orc::Model::Instance.new(instance_data, groups[key[:group]], session)
    end

    instances.group_by(&:cluster).map do |cluster_name, cluster_instances|
      Orc::Model::Application.new(:name => cluster_name,
                                  :instances => cluster_instances.sort_by(&:group_name),
                                  :mismatch_resolver => @mismatch_resolver)
    end
  end
end
