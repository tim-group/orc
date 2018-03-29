require 'orc/model/namespace'

class Orc::Model::Application
  attr_reader :instances, :name
  def initialize(args)
    @instances = args[:instances]
    @name = args[:name]
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass :mismatch resolver')
  end

  def participating_instances
    instances.select(&:in_pool?)
  end

  def get_proposed_resolutions
    proposed_resolutions = []
    @instances.each do |instance|
      proposed_resolutions << @mismatch_resolver.resolve(instance)
    end
    proposed_resolutions.sort_by(&:precedence)
  end
end
