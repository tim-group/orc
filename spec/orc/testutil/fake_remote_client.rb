class FakeRemoteClient
  def initialize(opts)
    @instances = opts[:instances]
    @instances = [
      { :group => "blue",
        :host => "h1",
        :version => "2.2",
        :application => "app",
        :participating => true,
        :health        => "healthy" },
      { :group => "blue",
        :host => "h2",
        :version => "2.2",
        :application => "app",
        :participating => true,
        :health        => "healthy" }
    ] if @instances.nil?

    @fail_to_deploy = opts[:fail_to_deploy]
  end

  def update_to_version(_spec, hosts, target_version)
    return @instances if @fail_to_deploy

    @instances = @instances.map do |instance|
      if (instance[:host] == hosts[0])
        instance[:version] = target_version
        instance
      else
        instance
      end
    end
  end

  def disable_participation(_spec, hosts)
    @instances = @instances.map do |instance|
      if (instance[:host] == hosts[0])
        instance[:participating] = false
        instance
      else
        instance
      end
    end
  end

  def enable_participation(_spec, hosts)
    @instances = @instances.map do |instance|
      if (instance[:host] == hosts[0])
        instance[:participating] = true
        instance
      else
        instance
      end
    end
  end

  def status(_spec)
    @instances
  end
end
