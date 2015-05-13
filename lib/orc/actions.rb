require 'orc/exceptions'
require 'orc/progress'

module Orc::Action
  class Base
    include Orc::Progress
    attr_reader :instance
    def initialize(remote_client, instance, timeout = nil)
      @instance = instance
      @remote_client = remote_client
      @timeout = timeout || default_timeout
    end

    def default_timeout
      nil
    end

    def check_valid(_application_model)
    end

    def timeout?
      ! @timeout.nil?
    end

    def complete?
      false
    end

    def key
      @instance.key
    end

    def host
      @instance.host
    end

    def group_name
      @instance.group_name
    end

    def execute(all_actions)
      do_execute(all_actions.clone) # clone to stop do_execute methods from being able to permute previous actions
    end

    def to_s
      self.class.name =~ /Orc::Action::(\w+)/
      type = Regexp.last_match(1)
      "#{type}: on #{host} #{group_name}"
    end
  end

  class UpdateVersionAction < Base
    def do_execute(all_actions)
      first_action = all_actions.pop
      while !all_actions[-1].nil? && all_actions[-1].class.name == self.class.name && all_actions[-1].key == key
        first_action = all_actions.pop
      end
      if self != first_action
        raise Orc::Exception::FailedToResolve.new("Action UpdateVersionAction re-run on same instance multiple times - instance failing to start.")
      end
      logger.log_action "deploying #{@instance.host} #{@instance.group_name} to version #{@instance.group.target_version}"

      response_received = @remote_client.update_to_version({ :group => @instance.group_name }, [@instance.host],
                                                           @instance.group.target_version)

      if !response_received
        raise Orc::Exception::FailedToResolve.new("Action UpdateVersionAction did not receive a response from #{@instance.host} within the timeout")
      end

      true
    end

    def precedence
      1
    end
  end

  class EnableParticipationAction < Base
    def default_timeout
      10
    end

    def do_execute(_all_actions)
      logger.log_action "enabling #{@instance.host} #{@instance.group.name}"
      successful = @remote_client.enable_participation({ :group => @instance.group.name }, [@instance.host])
      sleep(@timeout)
      successful
    end

    def precedence
      1
    end
  end

  class DisableParticipationAction < Base
    def default_timeout
      10
    end

    def check_valid(application_model)
      participating_instances = application_model.participating_instances.reject { |instance| instance == @instance }
      if (participating_instances.size == 0)
        raise Orc::Exception::FailedToResolve.new("Disabling participation for #{@instance.host} #{@instance.group.name} would result in zero participating instances - please resolve manually")
      end
    end

    def do_execute(_all_actions)
      logger.log_action "disabling #{@instance.host} #{@instance.group.name}"
      successful = @remote_client.disable_participation({ :group => @instance.group.name }, [@instance.host])
      sleep(@timeout)
      successful
    end

    def precedence
      3
    end
  end

  class WaitActionBase < Base
    attr_reader :start_time, :max_wait
    def initialize(*args)
      super
      @start_time = Time.now.to_i
      @max_wait ||= 25 * 60 # 25m
    end

    def do_execute(all_actions)
      first_action = all_actions.pop
      while !all_actions[-1].nil? && all_actions[-1].class.name == self.class.name
        first_action = all_actions.pop
      end
      has_waited_for = Time.now.to_i - first_action.start_time
      if has_waited_for > @max_wait
        # FIXME: Should we throw an exception here, or just return false to indicate the action failed?
        raise Orc::Exception::Timeout.new("Timed out after > #{@max_wait}s waiting #{self.class.name} for #{@instance.group.name} on #{@instance.host}")
      end
      logger.log_action "Waiting: #{self.class.name} for #{@instance.group.name} on #{@instance.host}: #{has_waited_for}s of #{@max_wait} seconds"
      true
    end

    def precedence
      2
    end
  end

  class WaitForHealthyAction < WaitActionBase
  end

  class WaitForDrainedAction < WaitActionBase
  end

  class ResolvedCompleteAction < Base
    def do_execute(_all_actions)
      true
    end

    def precedence
      4
    end

    def complete?
      true
    end
  end
end
