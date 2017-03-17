require 'orc/model/group'
require 'orc/model/namespace'

class Orc::Model::Instance
  attr_accessor :group
  attr_accessor :host
  attr_accessor :participation
  attr_accessor :version

  def initialize(instance, group, session=[])
    @group = group || raise("must pass in a not null group")
    @participation = instance[:participating]
    @version = instance[:version]
    @host = instance[:host]
    @healthy = instance[:health] == "healthy" ? true : false
    @stoppable = instance[:stoppable] == "unwise" ? false : true
    @session = session
  end

  def version_mismatch?
    version != group.target_version
  end

  def key
    {
      :group => group.name,
      :host  => host
    }
  end

  def has_restarted?
    @session.include?(key)
  end

  def set_restarted
    @session.push(key)
  end

  def healthy?
    @healthy
  end

  def participating?
    participation
  end

  def in_pool?
    (healthy? && participating?)
  end

  def stoppable?
    @stoppable
  end

  def group_name
    @group.name
  end
end
