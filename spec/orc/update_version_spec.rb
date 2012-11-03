$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/namespace.rb'
require 'model/instance_model'
require 'model/group_model'
require 'client/deploy_client'

describe Orc::UpdateVersionAction do

  before do
    @remote_client = double(Client::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Model::GroupModel.new(:name=>"blue",:target_version=>"16")
    instance_model = Model::InstanceModel.new({
      :host=>"host1"
    },group)

    update_version_action = Orc::UpdateVersionAction.new(@remote_client, instance_model)
    @remote_client.should_receive(:update_to_version).with( {:group=>"blue"}, ["host1"], "16")
    update_version_action.execute()
  end
end
