require 'model/namespace'
require 'model/instance_model'

class Model::ApplicationModel
  def initialize(instances)
    @instances = instances
  end

  def instances
    return @instances
  end

end

