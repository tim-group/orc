require 'orc/model/application'

class Orc::Engine
  def initialize(options)
    @application_model = options[:application_model] || raise("Need application model")
    @logger = options[:log] || raise("Need logger")
    @max_loop = 100
    @resolution_steps = []
    @debug = true
  end

  def execute_action(action)
    @resolution_steps.push action
    action.check_valid(@resolution_steps) # FIXME - This throws if invalid, execute returns false if invalid?
    if ! action.execute(@resolution_steps)
      raise Orc::Exception::FailedToResolve.new("Action #{action.class.name} failed")
    end
  end

  def resolve_one_step
    resolutions = @application_model.get_resolutions

    if (resolutions.size > 0)

      if @debug
        @logger.log("Useable resolutions:")
        resolutions.each { |r| @logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
      end

      execute_action resolutions[0]

    else
      @logger.log_resolution_complete(@resolution_steps)
      return true
    end

    false
  end

  def resolve()
     @loop_count = 0
     finished = false
     while( not finished ) do
       finished = resolve_one_step

       @loop_count += 1
       if (@loop_count > @max_loop)
         raise Orc::Exception::FailedToResolve.new("Aborted loop executed #{@loop_count} > #{@max_loop} times")
       end
     end
   end
end

