require 'orc/namespace'
require 'orc/actions'

class Orc::Engine
  def initialize(args)
    @live_model_creator = args[:live_model_creator]
    @mismatch_resolver = args[:mismatch_resolver]
    @progress_logger = args[:progress_logger]
    @max_loop = 100
  end

  def resolve()
    @live_model_creator.resolve()
  end
end

