require 'orc/model/group'
require 'orc/model/namespace'
require 'set'

class Orc::Model::Instance
  attr_accessor :group
  attr_accessor :host
  attr_accessor :participation
  attr_accessor :version
  attr_accessor :cluster

  def initialize(instance, group, session = {})
    @group = group || raise("must pass in a not null group")
    @participation = instance[:participating]
    @version = instance[:version]
    @host = instance[:host]
    @healthy = instance[:health] == "healthy" ? true : false
    @stoppable = instance[:stoppable] == "unwise" ? false : true
    @missing = instance[:missing] == true
    @cluster = "#{instance[:cluster] || 'default'}:#{instance[:application]}"
    @session = session
    @session[:restarted_instance_keys] = Set[] if @session[:restarted_instance_keys].nil?
    @session[:cleaning_instance_keys] = Set[] if @session[:cleaning_instance_keys].nil?
    @session[:provisioning_instance_keys] = Set[] if @session[:provisioning_instance_keys].nil?
    @session[:provisioning_instance_keys].delete(key) unless @missing
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

  def restarted?
    @session[:restarted_instance_keys].include?(key)
  end

  def set_restarted
    @session[:restarted_instance_keys].add(key)
  end

  def being_cleaned?
    @session[:cleaning_instance_keys].include?(key)
  end

  def set_being_cleaned
    raise "cannot clean an instance that is already absent" if @missing
    @session[:cleaning_instance_keys].add(key)
  end

  def being_provisioned?
    @session[:provisioning_instance_keys].include?(key)
  end

  def set_being_provisioned
    raise "cannot provision an instance that is already present" unless @missing
    @session[:cleaning_instance_keys].delete(key)
    @session[:provisioning_instance_keys].add(key)
  end

  def missing?
    @missing
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
