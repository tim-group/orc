require 'model/namespace'

class Model::GroupModel
  attr_accessor :name
  attr_accessor :target_version
  attr_accessor :target_participation
  def initialize(args={})
    @name = args[:name]
    @target_version = args[:target_version]
    @target_participation = args[:target_participation]
  end
end

