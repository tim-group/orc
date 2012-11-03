$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/namespace.rb'
require 'model/instance_model'
require 'model/group_model'
require 'client/deploy_client'

describe Orc::DisableParticipationAction do

  before do
    @remote_client = double(Client::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Model::GroupModel.new(:name=>"blue",:target_version=>"16")
    instance_model = Model::InstanceModel.new({
      :host=>"host1"
    },group)

    update_version_action = Orc::DisableParticipationAction.new(@remote_client, instance_model,0)
    @remote_client.should_receive(:disable_participation).with( {:group=>"blue"}, ["host1"])
    update_version_action.execute()
  end
end
