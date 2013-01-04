$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/actions'
require 'orc/model/instance'
require 'orc/model/group'
require 'client/deploy_client'

describe Orc::Action::UpdateVersionAction do

  before do
    @remote_client = double(Client::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Orc::Model::Group.new(:name=>"blue",:target_version=>"16")
    instance_model = Orc::Model::Instance.new({
      :host=>"host1"
    },group)

    update_version_action = Orc::Action::UpdateVersionAction.new(@remote_client, instance_model)
    @remote_client.should_receive(:update_to_version).with( {:group=>"blue"}, ["host1"], "16")
    update_version_action.execute([])
  end
end
