require 'orc/engine/actions'
require 'orc/factory'

describe Orc::Engine::Action::UpdateVersionAction do
  before do
    @remote_client = double(Orc::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Orc::Model::Group.new(:name => "blue", :target_version => "16")
    instance_model = Orc::Model::Instance.new({ :host => "host1" }, group)

    update_version_action = Orc::Engine::Action::UpdateVersionAction.new(
      :remote_client => @remote_client,
      :instance => instance_model)
    expect(@remote_client).to receive(:update_to_version).with({ :group => "blue" }, ["host1"], "16").and_return(true)
    update_version_action.execute([update_version_action])
  end

  it 'throws an exception if the agent timed out' do
    group = Orc::Model::Group.new(:name => "blue", :target_version => "16")
    instance_model = Orc::Model::Instance.new({ :host => "host1" }, group)

    update_version_action = Orc::Engine::Action::UpdateVersionAction.new(
      :remote_client => @remote_client,
      :instance => instance_model)
    allow(@remote_client).to receive(:update_to_version).and_return(false)
    expect { update_version_action.execute([update_version_action]) }.to raise_error(Orc::Engine::FailedToResolve)
  end

  def get_testaction(group_name = 'A')
    group = double
    allow(group).to receive(:name).and_return(group_name)
    allow(group).to receive(:target_version).and_return(1.1)
    instance = double
    allow(instance).to receive(:group).and_return(group)
    allow(instance).to receive(:group_name).and_return(group_name)
    allow(instance).to receive(:key).and_return(group_name)
    allow(instance).to receive(:host).and_return('localhost')
    remote_client = double
    allow(remote_client).to receive(:update_to_version).and_return(true)
    Orc::Engine::Action::UpdateVersionAction.new(:remote_client => remote_client, :instance => instance)
  end

  it 'works as expected' do
    i = get_testaction
    expect(i.do_execute([i])).to eql(true)
  end

  it 'works as expected for two actions in turn in different groups' do
    first = get_testaction
    second = get_testaction('B')
    expect(second.do_execute([first, second])).to eql(true)
  end

  it 'throws an exception if the same action for the same group is run twice' do
    first = get_testaction
    second = get_testaction
    expect { second.do_execute([first, second]) }.to raise_error(Orc::Engine::FailedToResolve)
  end
end
