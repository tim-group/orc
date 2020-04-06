require 'orc/engine/actions'
require 'orc/factory'

describe Orc::Engine::Action::DisableParticipationAction do
  before do
    @remote_client = double(Orc::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Orc::Model::Group.new(:name => "blue", :target_version => "16")
    instance_model = Orc::Model::Instance.new({ :host => "host1" }, group)

    update_version_action = Orc::Engine::Action::DisableParticipationAction.new(
      :remote_client => @remote_client,
      :instance => instance_model,
      :timeout => 0)
    expect(@remote_client).to receive(:disable_participation).with({ :group => "blue" }, ["host1"])
    update_version_action.execute([])

    expect(update_version_action.to_s).to eql('DisableParticipationAction: on host1 blue')
  end
end
