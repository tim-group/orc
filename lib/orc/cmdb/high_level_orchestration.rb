require 'orc/cmdb/namespace'

class Orc::CMDB::GroupActions
  def initialize(spec, logger)
    @spec = spec
    @logger = logger
  end

  def install(groups, version, for_group = 'all')
    swappable_groups = swappable(groups)

    groups.each do |group|
      if group[:name] == for_group || all_groups?(for_group)
        if group[:target_participation]
          if group[:never_swap]
            group[:target_version] = version
          elsif swappable_groups.size > 1
            @logger.log("Not installing to group #{group[:name]} - consider setting never_swap")
          end
        else
          group[:target_version] = version
        end
      end
    end

    if swappable_groups.size == 1
      if all_groups?(for_group)
        swappable_groups[0][:target_version] = version
      else
        @logger.log("Refusing to install: version: '#{version}' for group: '#{for_group}'. " \
          "Application: '#{@spec[:application]}', environment: '#{@spec[:environment]}'\n" \
          "Group 'blue' is the only swappable group (never_swap=false)\n" \
          "In order to install a new version using swap, a minimum of 2 swappable groups are required")
      end
    end

    groups
  end

  def limited_install(groups, version)
    min_group = groups.min_by { |g| Gem::Version.new(g[:target_version]) }
    min_group[:target_version] = version

    groups
  end

  def swap(groups, for_group = 'all')
    swappable_groups = swappable(groups)
    matched_group = swappable_groups.collect { |group| group[:name] }.include? for_group

    if matched_group || all_groups?(for_group)
      swappable_groups.each do |group|
        group[:target_participation] = !group[:target_participation]
      end if swappable_groups.size > 1
    end
    groups
  end

  private

  def all_groups?(for_group)
    for_group == 'all'
  end

  def swappable(groups)
    groups.reject { |group| group[:never_swap] }
  end
end

class Orc::CMDB::HighLevelOrchestration
  def initialize(args)
    @cmdb = args[:cmdb] || raise('Need :cmdb')
    @git = args[:git] || raise('Need :git')
    @environment = args[:environment] || raise('Need :environment')
    @application = args[:application] || raise('Need :application')
    @spec = { :environment => @environment, :application => @application }
    @logger = args[:logger] || Orc::Progress.logger
    @group_actions = Orc::CMDB::GroupActions.new(@spec, @logger)
  end

  def install(version, group = 'all')
    @git.update
    all_groups = @cmdb.retrieve_application(@spec)
    installed_groups = @group_actions.install(all_groups, version, group)
    @cmdb.save_application(@spec, installed_groups)
    @git.commit_and_push("#{@application} #{@environment}: installing #{version} for group #{group}")
  end

  def limited_install(version)
    @git.update
    groups = @cmdb.retrieve_application(@spec)
    installed_groups = @group_actions.limited_install(groups, version)
    @cmdb.save_application(@spec, installed_groups)
    @git.commit_and_push("#{@application} #{@environment}: install #{version} to one machine")
  end

  def swap
    @git.update
    groups = @cmdb.retrieve_application(@spec)
    swapped_groups = @group_actions.swap(groups)
    @cmdb.save_application(@spec, swapped_groups)
    @git.commit_and_push("#{@application} #{@environment}: swapping groups")
  end

  def deploy(version, group = 'all')
    @git.update
    groups = @cmdb.retrieve_application(@spec)
    installed_groups = @group_actions.install(groups, version, group)
    swapped_groups = @group_actions.swap(installed_groups, group)
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
