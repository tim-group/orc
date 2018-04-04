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

    session[:cleaning_instance_keys] = Set[] if session[:cleaning_instance_keys].nil?
    session[:provisioning_instance_keys] = Set[] if session[:provisioning_instance_keys].nil?

    groups = get_cmdb_groups
    statuses = @remote_client.status(:application => @application, :environment => @environment)

    clusters = statuses.group_by { |instance| "#{instance[:cluster] || 'default'}:#{instance[:application]}" }

    clusters.map do |name, instances|
      instance_models = instances.map do |instance|
        group = groups[instance[:group]]
        raise Orc::Model::GroupMissing.new("#{instance[:group]}") if group.nil?
        Orc::Model::Instance.new(instance, group, session)
      end

      missing_instance_keys = Set[] | session[:cleaning_instance_keys] | session[:provisioning_instance_keys]
      missing_instance_keys.subtract(instance_models.map(&:key))

      instance_models += missing_instance_keys.map do |key|
        Orc::Model::Instance.new(
          {
            :host => key[:host],
            :participating => false,
            :missing => true
          },
          groups[key[:group]],
          session)
      end

      Orc::Model::Application.new(:name => name,
                                  :instances => instance_models.sort_by(&:group_name),
                                  :mismatch_resolver => @mismatch_resolver)
    end
  end
end
