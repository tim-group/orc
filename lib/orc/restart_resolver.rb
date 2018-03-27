require 'orc/actions'

class Orc::RestartResolver
  def initialize(remote_client, timeout = nil)
    @remote_client = remote_client
    @timeout = timeout
    @restarted_instances = []
    @cases = {}
    in_case({
              :should_participate => true,
              :does_participate   => true,
              :needs_restart      => false,
              :is_healthy         => true
            }, 'ResolvedCompleteAction')
    in_case({
              :should_participate => true,
              :does_participate   => true,
              :needs_restart      => false,
              :is_healthy         => false
            }, 'WaitForHealthyAction')
    in_case({
              :should_participate => false,
              :does_participate   => false,
              :needs_restart      => false
            }, 'ResolvedCompleteAction')
    in_case({
              :should_participate => true,
              :does_participate   => true,
              :needs_restart      => true
            }, 'DisableParticipationAction')
    in_case({
              :does_participate   => false,
              :needs_restart      => true,
              :is_drained         => true
            }, 'RestartAction')
    in_case({
              :does_participate   => false,
              :needs_restart      => true,
              :is_drained         => false
            }, 'WaitForDrainedAction')
    in_case({
              :should_participate => true,
              :does_participate   => false,
              :needs_restart      => false,
              :is_healthy         => true
            }, 'EnableParticipationAction')
    in_case({
              :should_participate => true,
              :does_participate   => false,
              :needs_restart      => false,
              :is_healthy         => false
            }, 'WaitForHealthyAction')
    in_case({
              :should_participate => false,
              :does_participate   => true
            }, 'DisableParticipationAction')
  end

  def resolve(instance)
    get_case(
      :should_participate => instance.group.target_participation,
      :does_participate   => instance.participation,
      :needs_restart      => !instance.restarted?,
      :is_healthy         => instance.healthy?,
      :is_drained         => instance.stoppable? # FIXME: should come from model of LB connections instead?
    ).call(instance)
  end

  def set_restarted(instance)
    @restarted_instances = @restarted_instances.push(instance.key)
  end

  private

  def in_case(state, name)
    [
      :should_participate,
      :does_participate,
      :needs_restart,
      :is_healthy,
      :is_drained
    ].each do |k|
      if state[k].nil?
        t_state = state.clone
        f_state = state.clone
        t_state[k] = true
        f_state[k] = false
        in_case(t_state, name)
        in_case(f_state, name)
        return
      end
    end
    @cases[state] = lambda { |instance| Orc::Action.const_get(name).new(@remote_client, instance, @timeout) }
  end

  def get_case(state)
    @cases[state] || raise("CASE NOT HANDLED #{state}")
  end
end
