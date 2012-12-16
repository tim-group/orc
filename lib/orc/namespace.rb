require 'progress/log'

module Orc
  class NoNonParticipatingGroupsToUpdateException < Exception
  end

  class IllegalAttemptToEnableParticipation < Exception
  end

  class FailedToResolve < Exception
  end

  class GroupMissing < Exception
  end

  class UpdateVersionAction
    include Progress
    def initialize(remote_client, instance)
      @instance = instance
      @remote_client = remote_client
    end

    def check_valid(application_model)
    end

    def execute
      logger.log_action "deploying #{@instance.host} #{@instance.group.name} to version #{@instance.group.target_version}"

      return @remote_client.update_to_version({
        :group=>@instance.group.name,
      }, [@instance.host], @instance.group.target_version)

    end

    def precedence
      return 1
    end

  end

  class EnableParticipationAction
    include Progress
    def initialize(remote_client,instance, lb_waittime=10)
      @remote_client = remote_client
      @instance = instance
      @lb_waittime = lb_waittime
    end

    def check_valid(application_model)
    end

    def execute
      logger.log_action "enabling #{@instance.host} #{@instance.group.name}"
      successful = @remote_client.enable_participation({
        :group=>@instance.group.name,
      }, [@instance.host])
      sleep(@lb_waittime)
      return successful
    end

    def precedence
      return 1
    end
  end

  class DisableParticipationAction
    include Progress
    def initialize(remote_client, instance, lb_waittime=10)
      @remote_client = remote_client
      @instance = instance
      @lb_waittime = lb_waittime
    end

    def check_valid(application_model)
      participating_instances = application_model.instances.reject {|instance|!instance.participation or instance==@instance}
      if (participating_instances.size==0)
        raise Orc::FailedToResolve.new("action would result in zero participating instances - please resolve manually")
      end
    end

    def execute
      logger.log_action "disabling #{@instance.host} #{@instance.group.name}"
      successful = @remote_client.disable_participation({
        :group=>@instance.group.name,
      }, [@instance.host])
      sleep(@lb_waittime)
      return successful
    end

    def precedence
      return 2
    end
  end

  class ResolvedCompleteAction
    def initialize(instance={})
      @instance = instance
    end

    def check_valid(application_model)
    end

    def execute
    end

    def precedence
      return 3
    end
  end
end
