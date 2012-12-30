require 'orc/namespace'
require 'progress/log'

module Orc::Action
  class Base
    include Progress

    def initialize(remote_client, instance, timeout=nil)
      @instance = instance
      @remote_client = remote_client
      @timeout = timeout || default_timeout
    end

    def default_timeout
      nil
    end

    def check_valid(application_model)
    end

    def timeout?
      ! @timeout.nil?
    end

    def complete?
      false
    end
  end

  class UpdateVersionAction < Base
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

  class EnableParticipationAction < Base
    def default_timeout
      10
    end

    def execute
      logger.log_action "enabling #{@instance.host} #{@instance.group.name}"
      successful = @remote_client.enable_participation({
        :group=>@instance.group.name,
      }, [@instance.host])
      sleep(@timeout)
      return successful
    end

    def precedence
      return 1
    end
  end

  class DisableParticipationAction < Base
    def default_timeout
      10
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
      sleep(@timeout)
      return successful
    end

    def precedence
      return 2
    end
  end

  class ResolvedCompleteAction < Base
    def execute
    end

    def precedence
      return 3
    end

    def complete?
      true
    end
  end
end

