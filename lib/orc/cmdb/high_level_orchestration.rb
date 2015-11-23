require 'orc/cmdb/namespace'

class Orc::CMDB::GroupActions
  def install(groups, version, for_group = 'all')
    groups.each do |group|
      if group[:name] == for_group || for_group == 'all'
        if group[:target_participation]
          group[:target_version] = version if group[:never_swap]
        else
          group[:target_version] = version
        end
      end
    end

    if for_group == 'all'
      swappable_groups = groups.reject { |group| group[:never_swap] }
      if swappable_groups.size == 1
        swappable_groups[0][:target_version] = version
      end
    end

    groups
  end

  def swap(groups, for_group = 'all')
    swappable_groups = groups.reject { |group| group[:never_swap] }
    matched_group = swappable_groups.collect { |group| group[:name] }.include? for_group

    if matched_group || for_group == 'all'
      swappable_groups.each do |group|
        group[:target_participation] = !group[:target_participation]
      end if swappable_groups.size > 1
    end
    groups
  end
end

class Orc::CMDB::HighLevelOrchestration
  def initialize(args)
    @cmdb = args[:cmdb] || raise('Need :cmdb')
    @git = args[:git] || raise('Need :git')
    @environment = args[:environment] || raise('Need :environment')
    @application = args[:application] || raise('Need :application')
    @spec = { :environment => @environment, :application => @application }
    @groupActions = Orc::CMDB::GroupActions.new
  end

  def install(version, group = 'all')
    @git.update
    all_groups = @cmdb.retrieve_application(@spec)
    installed_groups = @groupActions.install(all_groups, version, group)
    @cmdb.save_application(@spec, installed_groups)
    @git.commit_and_push("#{@application} #{@environment}: installing #{version} for group #{group}")
  end

  def swap
    @git.update
    groups = @cmdb.retrieve_application(@spec)
    swapped_groups = @groupActions.swap(groups)
    @cmdb.save_application(@spec, swapped_groups)
    @git.commit_and_push("#{@application} #{@environment}: swapping groups")
  end

  def deploy(version, group = 'all')
    @git.update
    groups = @cmdb.retrieve_application(@spec)
    installed_groups = @groupActions.install(groups, version, group)
    swapped_groups = @groupActions.swap(installed_groups, group)
    @cmdb.save_application(@spec, swapped_groups)
    @git.commit_and_push("#{@application} #{@environment}: deploying #{version}")
  end

  def promote_from_environment(upstream_environment)
    @git.update
    from_spec = {
      :environment => upstream_environment,
      :application => @spec[:application]
    }

    from_app = @cmdb.retrieve_application(from_spec)
    groups_participating = from_app.reject { |group| !group[:target_participation] }
    groups_participating.each do|group|
      deploy(group[:target_version])
    end
  end
end
