require 'orc/namespace'

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

      proposed_resolutions = []
      application_model.instances.each do |instance|
        proposed_resolutions << @group_mismatch_resolver.resolve(instance)
      end

      sorted_resolutions =
      proposed_resolutions.sort_by {
        |resolution|
        resolution.precedence()
      }.reject {
        |resolution|
        resolution.kind_of?Orc::ResolvedCompleteAction
      }

      if (sorted_resolutions.size>0)
        action = sorted_resolutions.shift
        action.check_valid(application_model)
        action.execute()
      else
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
