require 'orc/model/application'

class Orc::Engine
  def initialize(options)
    @application_model = options[:application_model] || raise("Need application model")
    @logger = options[:log] || raise("Need logger")
  end

  def resolve_one_step
    @application_model.resolve_one_step
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

