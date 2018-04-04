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
    @delayed_effects = []
  end

  def update_to_version(_spec, hosts, target_version)
    return @instances if @fail_to_deploy

    @instances = @instances.map do |instance|
      if (instance[:host] == hosts[0])
        instance[:version] = target_version
        instance[:health] = 'ill'
        @delayed_effects.push({:delay => 1, :mutator => Proc.new do |instances|
          instances.detect { |i| i[:host] == hosts[0] }[:health] = 'healthy'
        end})
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
        @delayed_effects.push({:delay => 1, :mutator => Proc.new do |instances|
          instances.detect { |i| i[:host] == hosts[0] }[:stoppable] = 'safe'
        end})
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
    @delayed_effects.push({:delay => 0, :mutator => Proc.new do |instances|
      @cleaned_instances[host] = instances.detect { |instance| instance[:host] == host }
      instances.delete_if { |instance| instance[:host] == host }
    end})
  end

  def provision_instance(host)
    @delayed_effects.push({:delay => 0, :mutator => Proc.new do |instances|
      provisioned_instance = @cleaned_instances[host]
      @cleaned_instances.delete(host)
      provisioned_instance[:version] = "5"
      provisioned_instance[:health] = "ill"
      instances.push(provisioned_instance)
    end})
    @delayed_effects.push({:delay => 2, :mutator => Proc.new do |instances|
      instances.detect { |instance| instance[:host] == host }[:health] = 'healthy'
    end})
  end

  def status(_spec)
    result = @instances.clone
    @delayed_effects.each { |effect|
      effect[:mutator].call(@instances) if effect[:delay] == 0
      effect[:delay] -= 1
    }
    @delayed_effects.delete_if { |e| e[:delay] < 0 }
    result
  end

  def restart(_spec, _hosts)
    true
  end
end
