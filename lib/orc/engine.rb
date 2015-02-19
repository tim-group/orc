require 'orc/model/application'

class Orc::Engine
  attr_reader :debug
  def initialize(options)
    @model_generator = options[:model_generator] || raise("Needs model generator")
    @logger = options[:log] || raise("Need :log")
    @max_loop = 1000
    @resolution_steps = []
    @debug = false
  end

  def execute_action(action, application_model)
    @resolution_steps.push action
    action.check_valid(application_model) # FIXME - This throws if invalid, execute returns false if invalid?
    if !action.execute(@resolution_steps)
      raise Orc::Exception::FailedToResolve.new("Action #{action.class.name} failed")
    end
  end

  def resolve_one_step(resolutions, application_model)
    if resolutions.size > 0

      if debug
        @logger.log("Useable resolutions:")
        resolutions.each { |r| @logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
      end

      execute_action resolutions[0], application_model
    else
      @logger.log_resolution_complete(@resolution_steps)
      return true
    end

    false
  end

  def resolve
    @loop_count = 0
    finished = false
    while !finished do
      application_models = @model_generator.create_live_model()
      all_resolutions = application_models.map { |model| [model, model.get_resolutions] }

      finished = all_resolutions.map do |model, resolutions|
        @logger.log("resolving one step for #{model.name}")
        resolve_one_step(resolutions, model)
      end.reduce(true) { |a, b| a && b }

      @loop_count += 1
      if @loop_count > @max_loop
        raise Orc::Exception::FailedToResolve.new("Aborted loop executed #{@loop_count} > #{@max_loop} times")
      end
    end

    @resolution_steps.map { |step| step.to_s }
  end
end
