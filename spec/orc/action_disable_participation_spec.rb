$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/actions'
require 'orc/model/instance'
require 'orc/model/group'
require 'orc/deploy_client'

describe Orc::Action::DisableParticipationAction do

  before do
    @remote_client = double(Orc::DeployClient)
  end

  it 'sends an update message to the given host' do
    group = Orc::Model::Group.new(:name=>"blue",:target_version=>"16")
    instance_model = Orc::Model::Instance.new({
      :host=>"host1"
    },group)

    update_version_action = Orc::Action::DisableParticipationAction.new(@remote_client, instance_model,0)
    @remote_client.should_receive(:disable_participation).with( {:group=>"blue"}, ["host1"])
    update_version_action.execute([])

    update_version_action.to_s.should eql('DisableParticipationAction: on host1 blue')
  end
end
