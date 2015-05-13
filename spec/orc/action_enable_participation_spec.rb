describe Orc::Action::EnableParticipationAction do
  before do
    @remote_client = double(Orc::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Orc::Model::Group.new(:name => "blue", :target_version => "16")
    instance_model = Orc::Model::Instance.new({
      :host => "host1"
    }, group)

    update_version_action = Orc::Action::EnableParticipationAction.new(@remote_client, instance_model, 0)
    @remote_client.should_receive(:enable_participation).with({ :group => "blue" }, ["host1"])
    update_version_action.execute([])
  end
end
