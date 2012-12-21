require 'model/namespace'
require 'model/group_model'

class Model::InstanceModel
  attr_accessor :group
  attr_accessor :participation
  attr_accessor :version
  attr_accessor :host

  def initialize(instance, group)
    @group = group || raise("must pass in a not null group")
    @participation = instance[:participating]
    @version = instance[:version]
    @host = instance[:host]
    @failed = false
  end

  def version_mismatch?
    return self.version != group.target_version
  end

  def key()
    return {
      :group=>group.name,
      :host=>host
    }
  end

  def fail
    @failed = true
  end

  def failed?
    return @failed
  end
end

