class FakeRemoteClient
  def initialize(opts)
    @instances = opts[:instances]
    @instances = [
      { :group => "blue",
        :host => "h1",
        :version => "2.2",
        :application => "app",
        :participating => true,
        :health        => "healthy",
        :stoppable     => "safe" },
      { :group => "blue",
        :host => "h2",
        :version => "2.2",
        :application => "app",
        :participating => true,
        :health        => "healthy",
        :stoppable     => "safe" }
    ] if @instances.nil?

    @cleaned_instances = {}
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

  def clean_instance(host)
    @cleaned_instances[host] = @instances.detect { |instance| instance[:host] == host }
    @instances.delete_if { |instance| instance[:host] == host }
  end

  def provision_instance(host)
    provisioned_instance = @cleaned_instances[host]
    @cleaned_instances.delete(host)
    provisioned_instance[:version] = "5"
    @instances.push(provisioned_instance)
  end

  def status(_spec)
    @instances
  end

  def restart(_spec, _hosts)
    true
  end
end
