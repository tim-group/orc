require 'orc/engine/namespace'

class Orc::Engine::Engine
  def initialize(options)
    @model_generator = options[:model_generator] || raise("Needs model generator")
    @logger = options[:log] || raise("Need :log")
    @max_loop = 10_000
    @resolution_steps = []
    @options = options
  end

  def resolve
    session = {}
    @loop_count = 0
    finished = false
    while !finished
      application_models = @model_generator.create_live_model(session)
      all_resolutions = application_models.map { |model| [model, get_usable_resolutions(model)] }

      finished = all_resolutions.map do |model, resolutions|
        @logger.log("resolving one step for #{model.name}")
        resolve_one_step(resolutions, model)
      end.reduce(true) { |a, e| a && e }

      @loop_count += 1
      if @loop_count > @max_loop
        raise Orc::Engine::FailedToResolve.new("Aborted loop executed #{@loop_count} > #{@max_loop} times")
      end
    end

    @resolution_steps.map(&:to_s)
  end

  def required_resolutions
    application_models = @model_generator.create_live_model({})
    application_models.flat_map { |model| get_usable_resolutions(model) }
  end

  def check_rolling_restart_possible
    raise Orc::Engine::FailedToResolve.new("Rolling restart not possible as unresolved steps") \
                                              unless required_resolutions.empty?
  end

  private

  def get_usable_resolutions(application_model)
    proposed_resolutions = application_model.get_proposed_resolutions

    if @options[:debug]
      @logger.log("Proposed resolutions:")
      proposed_resolutions.each { |r| @logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
    end

    incomplete_resolutions = proposed_resolutions.reject(&:complete?)

    useable_resolutions = incomplete_resolutions.reject do |resolution|
      reject = true
      begin
        resolution.check_valid(application_model)
        reject = false
      rescue Exception
      end
      reject
    end

    if useable_resolutions.size == 0 && incomplete_resolutions.size > 0
      raise Orc::Engine::FailedToResolve.new("Needed actions to resolve, but no actions could be taken (all " \
      "result in invalid state) - manual intervention required")
    end

    useable_resolutions
  end

  def resolve_one_step(resolutions, application_model)
    if resolutions.size > 0

      if @options[:debug]
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

  def execute_action(action, application_model)
    @resolution_steps.push action
    action.check_valid(application_model) # FIXME: This throws if invalid, execute returns false if invalid?
    if !action.execute(@resolution_steps)
      raise Orc::Engine::FailedToResolve.new("Action #{action.class.name} failed")
    end
  end
end
