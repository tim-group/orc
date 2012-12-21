require 'orc/actions'

class Orc::MismatchResolver
  def in_case(state, name)
    @cases[state] = lambda {|instance| Orc::Action.const_get(name).new(@remote_client,instance)}
  end

  def initialize(remote_client)
    @remote_client = remote_client
    @cases = {}
    in_case({
      :should_participate=>true,
      :does_participate=>true,
      :version_mismatch=>false
    }, 'ResolvedCompleteAction')
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>false
    }, 'ResolvedCompleteAction')
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, 'UpdateVersionAction')
    in_case({
      :should_participate=>true,
      :does_participate=>true,
      :version_mismatch=>true
    }, 'DisableParticipationAction')
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, 'UpdateVersionAction')
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>true
    }, 'UpdateVersionAction')
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>false
    }, 'EnableParticipationAction')
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>false
    }, 'DisableParticipationAction')
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>true
    }, 'DisableParticipationAction')
  end

  def get_case(state)
    return @cases[state] || raise("CASE NOT HANDLED #{state}")
  end

  def resolve(instance)
    return get_case(
      :should_participate => instance.group.target_participation,
      :does_participate   => instance.participation,
      :version_mismatch   => instance.version_mismatch?
    ).call(instance)
  end
end

