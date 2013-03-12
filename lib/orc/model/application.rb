require 'orc/exceptions'
require 'orc/cmdb/namespace'
require 'orc/actions'
require 'orc/model/group'
require 'orc/model/instance'

class Orc::Model::Application
  attr_reader :instances
  def initialize(args)
    @remote_client = args[:remote_client] || raise('Nust pass :remote_client')
    @cmdb = args[:cmdb]
    @environment = args[:environment] || raise('Must pass :environment')
    @application = args[:application] || raise('Must pass :application')
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass :mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass :progress_logger')
    @max_loop = 100
    @debug = false
  end

  def get_cmdb_groups
    return @groups unless @groups.nil?
    cmdb_model_for_app = @cmdb.retrieve_application(:environment=>@environment, :application=>@application)
    raise Orc::CMDB::ApplicationMissing.new("#{@application} not found in CMDB for environment:#{@environment}") if cmdb_model_for_app.nil?
    @groups = {}
    cmdb_model_for_app.each do |group|
      @groups[group[:name]] = Orc::Model::Group.new(group)
    end
    @groups
  end

  def create_live_model()
    groups = get_cmdb_groups()
    statuses = @remote_client.status(:application => @application, :environment => @environment)

    instance_models = []
    statuses.each do |instance|
      group = groups[instance[:group]]
      raise Orc::Exception::GroupMissing.new("#{instance[:group]}") if group.nil?
      instance_models << Orc::Model::Instance.new(instance, group)
    end
    @instances = instance_models.sort_by { |instance| instance.group_name }
  end

  def participating_instances
    instances.select { |instance| instance.is_in_pool? }
  end

  def get_proposed_resolutions_for(live_instances)
    proposed_resolutions =[]
    live_instances.each do |instance|
      proposed_resolutions << @mismatch_resolver.resolve(instance)
    end
    proposed_resolutions.sort_by { |resolution| resolution.precedence }
  end

  def get_resolutions
    @progress_logger.log("creating live model")

    live_instances = create_live_model

    proposed_resolutions = get_proposed_resolutions_for live_instances

    if @debug
      @progress_logger.log("Proposed resolutions:")
      proposed_resolutions.each { |r| @progress_logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
    end

    incomplete_resolutions = proposed_resolutions.reject { |resolution|
      resolution.complete?
    }

    useable_resolutions = incomplete_resolutions.reject { |resolution|
      reject = true
      begin
        resolution.check_valid(self)
        reject = false
      rescue Exception => e
        #puts "Exception from #{resolution.to_s} was #{e}"
      end
      reject
    }

    if useable_resolutions.size == 0 and incomplete_resolutions.size > 0
      raise Orc::Exception::FailedToResolve.new("Needed actions to resolve, but no actions could be taken (all result in invalid state) - manual intervention required")
    end

    useable_resolutions
  end
end

