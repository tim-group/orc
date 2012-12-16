require 'orc/namespace'
require 'cmdb/namespace'
require 'model/application_model'

class Orc::LiveModelCreator

  def initialize(args)
    @remote_client = args[:remote_client]
    @cmdb = args[:cmdb]
    @instance_models = {}
 end

  def create_live_model(environment, application)
    statuses = @remote_client.status(:environment=>environment, :application=>application)
    application_model = @cmdb.retrieve_application(:environment=>environment, :application=>application)
    groups = {}

    raise CMDB::ApplicationMissing.new("#{application} not found in CMDB for environment:#{environment}") if application_model.nil?

    application_model.each do |group|
      groups[group[:name]] = Model::GroupModel.new(group)
    end

    models = []
    statuses.instances.each do |instance|
      group = groups[instance[:group]]
      raise Orc::GroupMissing.new("#{instance[:group]}") if group.nil?
      instance_model = Model::InstanceModel.new(instance, group)
      previous = @instance_models[instance_model.key]
      if previous!=nil and previous.failed?
        instance_model.fail
      else
        @instance_models[instance_model.key] = instance_model
     end

     models << instance_model
    end

    return Model::ApplicationModel.new(models)
  end

end
