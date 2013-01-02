require 'orc/namespace'
require 'cmdb/namespace'
require 'orc/actions'

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
    @models || raise("We have not yet calculated the instances")
  end

  def resolve()
    @loop_count=0
    while(true) do
      @progress_logger.log("creating live model")
      application_model = self.create_live_model()
      proposed_resolutions =[]
      instances.each do |instance|
        proposed_resolutions << {
            :instance=>instance,
            :resolution=>@mismatch_resolver.resolve(instance)
        }
      end

      sorted_resolutions = proposed_resolutions.sort_by { |resolution_pair|
        resolution_pair[:resolution].precedence()
      }.reject { |resolution_pair|
        resolution_pair[:resolution].complete? or resolution_pair[:instance].failed?
      }

      if (sorted_resolutions.size>0)
        next_resolution = sorted_resolutions.shift
        action = next_resolution[:resolution]
        action.check_valid(application_model)
        action_successful = action.execute()

        if action_successful == false
          next_resolution[:instance].fail
        end
      else
        if (application_model.instances.reject {|instance| not instance.failed?}.size>0)
          raise Orc::FailedToResolve.new("Some instances failed actions, see logs")
        end

        @progress_logger.log_resolution_complete()
        break
      end

      @loop_count+=1
      if (@loop_count>100)
        raise Orc::FailedToResolve.new("Aborted loop executed #{@loop_count} > #{@max_loop} times")
      end
    end
  end
end

