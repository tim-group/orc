class Statuses
  def initialize(instances)
    @instances = instances
  end

  def unique_hosts
    hosts = @instances.map do |instance|
      instance[:host]
    end
    return hosts.uniq
  end

  def instances
    return @instances
  end

  def each
    return instances.each
  end

  def count
    return @instances.size()
  end
end