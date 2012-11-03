require 'orc/namespace'

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
    }, lambda {|instance| Orc::ResolvedCompleteAction.new()})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>false
    }, lambda {|instance| Orc::ResolvedCompleteAction.new()})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>true,
      :version_mismatch=>true
    }, lambda {|instance| Orc::DisableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>true
    }, lambda {|instance| Orc::UpdateVersionAction.new(remote_client,instance)})
    in_case({
      :should_participate=>true,
      :does_participate=>false,
      :version_mismatch=>false
    }, lambda {|instance| Orc::EnableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>false
    }, lambda {|instance| Orc::DisableParticipationAction.new(remote_client,instance)})
    in_case({
      :should_participate=>false,
      :does_participate=>true,
      :version_mismatch=>true
    }, lambda {|instance| Orc::DisableParticipationAction.new(remote_client,instance)})

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
