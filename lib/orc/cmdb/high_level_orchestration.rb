require 'orc/cmdb/namespace'

class Orc::CMDB::HighLevelOrchrestration
  def initialize(args)
    @cmdb = args[:cmdb] || raise('Need :cmdb')
    @git = args[:git] || raise('Need :git')
    @environment = args[:environment] || raise('Need :environment')
    @application = args[:application] || raise('Need :application')
    @spec = {:environment => @environment, :application=>@application}
  end

  def install(version,groups_filter=nil)
    all_groups=@cmdb.retrieve_application(@spec)
    @git.update()
    if (groups_filter.nil?)
      _install(all_groups,version)
      @cmdb.save_application(@spec, all_groups)
    else
      ignored_groups = all_groups.reject { |group| groups_filter.include?(group[:name]) }
      groups = all_groups.reject { |k| !groups_filter.include?(k[:name]) }
      _install(groups,version)
      @cmdb.save_application(@spec, groups.concat(ignored_groups))
    end
    @git.commit_and_push("#{@application} #{@environment}: installing #{version}")
  end

  def swap()
    @git.update()
    groups = @cmdb.retrieve_application(@spec)
    _swap(groups)
    @cmdb.save_application(@spec, groups)
    @git.commit_and_push("#{@application} #{@environment}: swapping groups")
  end

  def deploy(version)
    @git.update()
    groups = @cmdb.retrieve_application(@spec)
    _install(groups,version)
    _swap(groups)
    @cmdb.save_application(@spec, groups)
    @git.commit_and_push("#{@application} #{@environment}: deploying #{version}")
  end

  def promote_from_environment(upstream_environment)
    @git.update()
    from_spec = {
      :environment=>upstream_environment,
      :application=>@spec[:application]
    }

    upstream_highlevel_orc = Orc::CMDB::HighLevelOrchrestration.new(
      :cmdb=>@cmdb,
      :git=>@git,
      :environment=>from_spec[:environment],
      :application=>from_spec[:application])

    from_app = @cmdb.retrieve_application(from_spec)
    groups_participating = from_app.reject {|group| !group[:target_participation]}
    groups_participating.each {|group|
      self.deploy(group[:target_version])
    }
  end

  def _swap(groups)
    swappable_groups = groups.reject {|group| group[:never_swap] == true}
    swappable_groups.each { |group|
      group[:target_participation] = !group[:target_participation]
    } if swappable_groups.size > 1
  end

  def _install(groups,version)
    groups.each { |group|
      if (!group[:target_participation])
        group[:target_version] = version
      end
    }

    swappable_groups = groups.reject {|group| group[:never_swap] == true}
    if (swappable_groups.size==1)
      swappable_groups[0][:target_version] = version
    end

  end

end
