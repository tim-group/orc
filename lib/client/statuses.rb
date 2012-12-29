class Statuses
  attr_reader :instances

  def initialize(instances)
    @instances = instances
  end

  def unique_hosts
    hosts = @instances.map do |instance|
      instance[:host]
    end
    return hosts.uniq
  end

  def each
    return instances.each
  end

  def count
    return @instances.size()
  end
end

