require 'orc/namespace'
require 'cmdb/namespace'
require 'orc/actions'
require 'model/group_model'
require 'model/instance_model'

class Orc::LiveModelCreator

  def initialize(args)
    @remote_client = args[:remote_client]
    @cmdb = args[:cmdb]
    @instance_models = {}
    @instance_actions = {}
    @environment = args[:environment] || raise('Must pass environment')
    @application = args[:application] || raise('Must pass application')
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass progress_logger')
    @max_loop = 100
  end

  def get_cmdb_groups
    return @groups unless @groups.nil?
    cmdb_model_for_app = @cmdb.retrieve_application(:environment=>@environment, :application=>@application)
    raise CMDB::ApplicationMissing.new("#{@application} not found in CMDB for environment:#{@environment}") if cmdb_model_for_app.nil?
    @groups = {}
    cmdb_model_for_app.each do |group|
      @groups[group[:name]] = Model::GroupModel.new(group)
    end
    @groups
  end

  def create_live_model()
    groups = get_cmdb_groups()
    statuses = @remote_client.status(:environment=>@environment, :application=>@application)

    statuses.each do |instance|
      group = groups[instance[:group]]
      raise Orc::GroupMissing.new("#{instance[:group]}") if group.nil?
      instance_model = Model::InstanceModel.new(instance, group)
      @instance_models[instance_model.key] = instance_model
    end

    return self
  end

  def instances
    @instance_models.values || raise("We have not yet calculated the instances")
  end

  def has_failed_actions(action)
    return false if @instance_actions[action.key].nil?
    failed_actions = @instance_actions[action.key].reject { |action| not action.failed? }
    failed_actions.size > 0
  end

  def resolve()
    @loop_count=0
    while(true) do
      @progress_logger.log("creating live model")
      create_live_model()
      proposed_resolutions =[]
      instances.each do |instance|
        proposed_resolutions << @mismatch_resolver.resolve(instance)
      end

      sorted_resolutions = proposed_resolutions.sort_by { |resolution|
        resolution.precedence()
      }.reject { |resolution|
        resolution.complete? or has_failed_actions(resolution)
      }

      if (sorted_resolutions.size>0)
        action = sorted_resolutions.shift
        action.check_valid(self)
        success = action.execute()

        if @instance_actions[action.key].nil?
          @instance_actions[action.key] = []
        end
        @instance_actions[action.key].push action
      else
        if (instances.reject {|instance| not has_failed_actions(instance) }.size>0)
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

