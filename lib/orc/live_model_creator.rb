require 'orc/namespace'
require 'cmdb/namespace'

class Orc::LiveModelCreator

  def initialize(args)
    @remote_client = args[:remote_client]
    @cmdb = args[:cmdb]
    @instance_models = {}
    @environment = args[:environment] || raise('Must pass environment')
    @application = args[:application] || raise('Must pass application')
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass progress_logger')
    @max_loop = 100
  end

  def create_live_model()
    statuses = @remote_client.status(:environment=>@environment, :application=>@application)
    application_model = @cmdb.retrieve_application(:environment=>@environment, :application=>@application)
    groups = {}

    raise CMDB::ApplicationMissing.new("#{@application} not found in CMDB for environment:#{@environment}") if application_model.nil?

    application_model.each do |group|
      groups[group[:name]] = Model::GroupModel.new(group)
    end

    @models = []
    statuses.instances.each do |instance|
      group = groups[instance[:group]]
      raise Orc::GroupMissing.new("#{instance[:group]}") if group.nil?
      instance_model = Model::InstanceModel.new(instance, group)
      previous = @instance_models[instance_model.key]
      if previous!=nil and previous.failed?
        instance_model.fail
      end
      @instance_models[instance_model.key] = instance_model

      @models << instance_model
    end

    return self
  end

  def instances
    @models
  end

end

