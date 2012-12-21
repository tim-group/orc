require 'orc/actions'

class Orc::MismatchResolver
  def in_case(state, closure)
    @cases[state] = closure
  end

  def initialize(remote_client)
    @cases = {}
    in_case({
      :should_participate=>true,
      :does_participate=>true,
      :version_mismatch=>false
    }, lambda {|instance| Orc::Action::ResolvedCompleteAction.new()})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>false
    }, lambda {|instance| Orc::Action::ResolvedCompleteAction.new()})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::Action::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>true,
      :version_mismatch=>true
    }, lambda {|instance| Orc::Action::DisableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::Action::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::Action::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>false
    }, lambda {|instance| Orc::Action::EnableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>false
    }, lambda {|instance| Orc::Action::DisableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>true
    }, lambda {|instance| Orc::Action::DisableParticipationAction.new(remote_client,instance)})

  end

  def get_case(state)
    return @cases[state] || raise("CASE NOT HANDLED #{state}")
  end

  def resolve(instance)
    return get_case(
    :should_participate=>instance.group.target_participation,
    :does_participate=>instance.participation,
    :version_mismatch=>instance.version_mismatch?
    ).call(instance)
  end
end

