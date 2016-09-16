require 'orc/model/application'

class Orc::Engine
  def initialize(options)
    @model_generator = options[:model_generator] || raise("Needs model generator")
    @logger = options[:log] || raise("Need :log")
    @max_loop = 10000
    @resolution_steps = []
    @options = options
  end

  def resolve
    @loop_count = 0
    finished = false
    while !finished
      application_models = @model_generator.create_live_model
      all_resolutions = application_models.map { |model| [model, model.get_resolutions] }

      finished = all_resolutions.map do |model, resolutions|
        @logger.log("resolving one step for #{model.name}")
        resolve_one_step(resolutions, model)
      end.reduce(true) { |a, e| a && e }

      @loop_count += 1
      if @loop_count > @max_loop
        raise Orc::Exception::FailedToResolve.new("Aborted loop executed #{@loop_count} > #{@max_loop} times")
      end
    end

    @resolution_steps.map(&:to_s)
  end

  def rolling_restart
    application_models = @model_generator.create_live_model
    all_resolutions = application_models.flat_map(&:get_resolutions)

    if all_resolutions.empty?
      print "--rolling-restart command would execute, nothing to resolve\n"
      print "--rolling-restart command not yet available. Under development.\n"
    else
      raise Orc::Exception::CannotRestartUnresolvedGroup.new("hah!")
    end
  end

  private

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
      raise Orc::Exception::FailedToResolve.new("Action #{action.class.name} failed")
    end
  end
end
