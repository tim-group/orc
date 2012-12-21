require 'orc/namespace'
require 'orc/actions'

class Orc::Engine
  def initialize(args)
    @environment = args[:environment]
    @application = args[:application]
    @live_model_creator = args[:live_model_creator]
    @group_mismatch_resolver = args[:group_mismatch_resolver]
    @progress_logger = args[:progress_logger]
    @max_loop = 100
  end

  def resolve()
    @loop_count=0
    while(true) do
      @progress_logger.log("creating live model")
      application_model = @live_model_creator.create_live_model(@environment, @application)
      proposed_resolutions =[]
      application_model.instances.each do |instance|
        proposed_resolutions << {
            :instance=>instance,
            :resolution=>@group_mismatch_resolver.resolve(instance)
        }
      end

      sorted_resolutions = proposed_resolutions.sort_by { |resolution_pair|
        resolution_pair[:resolution].precedence()
      }.reject { |resolution_pair|
        resolution_pair[:resolution].kind_of? Orc::Action::ResolvedCompleteAction or resolution_pair[:instance].failed?
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

