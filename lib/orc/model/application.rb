require 'orc/exceptions'
require 'cmdb/namespace'
require 'orc/actions'
require 'orc/model/group'
require 'orc/model/instance'

class Orc::Model::Application

  def initialize(args)
    @remote_client = args[:remote_client]
    @cmdb = args[:cmdb]
    @instance_actions = {}
    @environment = args[:environment] || raise('Must pass environment')
    @application = args[:application] || raise('Must pass application')
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass progress_logger')
    @max_loop = 100
    @debug = false
  end

  def get_cmdb_groups
    return @groups unless @groups.nil?
    cmdb_model_for_app = @cmdb.retrieve_application(:environment=>@environment, :application=>@application)
    raise CMDB::ApplicationMissing.new("#{@application} not found in CMDB for environment:#{@environment}") if cmdb_model_for_app.nil?
    @groups = {}
    cmdb_model_for_app.each do |group|
      @groups[group[:name]] = Orc::Model::Group.new(group)
    end
    @groups
  end

  def create_live_model()
    groups = get_cmdb_groups()
    statuses = @remote_client.status(:environment=>@environment, :application=>@application)

    instance_models = []
    statuses.each do |instance|
      group = groups[instance[:group]]
      raise Orc::Exception::GroupMissing.new("#{instance[:group]}") if group.nil?
      instance_models << Orc::Model::Instance.new(instance, group)
    end
    instance_models.sort_by { |instance| instance.group_name }
  end

  def instances
    actions = @instance_actions.values || raise("We have not yet calculated the instances")
    instances = []
    actions.each { |l| a = l[-1]; instances << a.instance if a != nil }
    instances
  end

  def participating_instances
    instances.reject { |instance| not instance.participation }
  end

  def has_failed_actions(action)
    return false if @instance_actions[action.key].nil?
    failed_actions = @instance_actions[action.key].reject { |action| not action.failed? }
    failed_actions.size > 0
  end

  def get_proposed_resolutions_for(live_instances)
    proposed_resolutions =[]
    live_instances.each do |instance|
      proposed_resolutions << @mismatch_resolver.resolve(instance)
    end
    proposed_resolutions.sort_by { |resolution| resolution.precedence }
  end

  def execute_action(action)
    action.check_valid(self)
    action.execute(@instance_actions[action.key])
  end

  def resolve_one_step
    @progress_logger.log("creating live model")
    live_instances = create_live_model
    proposed_resolutions = get_proposed_resolutions_for live_instances

    if @debug
      @progress_logger.log("Proposed resolutions:")
      proposed_resolutions.each { |r| @progress_logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
    end

    useable_resolutions = proposed_resolutions.reject { |resolution|
      resolution.complete? or has_failed_actions(resolution)
    }

    useable_resolutions.each do |action|
      if @instance_actions[action.key].nil?
        @instance_actions[action.key] = []
      end
      @instance_actions[action.key].push action
    end

    if (useable_resolutions.size>0)
      if @debug
        @progress_logger.log("Useable resolutions:")
        useable_resolutions.each { |r| @progress_logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
      end

      execute_action useable_resolutions[0]
    else
      if (instances.reject {|instance| not has_failed_actions(instance) }.size > 0)
        raise Orc::Exception::FailedToResolve.new("Some instances failed actions, see logs")
      end

      @progress_logger.log_resolution_complete()
      return true
    end
    false
  end
end

