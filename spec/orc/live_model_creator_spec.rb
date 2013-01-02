$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/live_model_creator'
require 'client/statuses'

describe Orc::LiveModelCreator do
  before do
    @remote_client = double()
    @cmdb = double()
  end

  it 'gives sensible error message when cmdb info is missing' do
    environment="env"
    application="app"
    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(Statuses.new([]))
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(nil)

    live_model_creator = Orc::LiveModelCreator.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application)

    expect {
      live_model = live_model_creator.create_live_model()
    }.to raise_error(CMDB::ApplicationMissing)
  end

  it 'combines the results from the remote_client with the cmdb information' do
    blue_instance = {:group=>"blue", :version=>"2.2", :application=>"app1"}
    green_instance = {:group=>"green", :version=>"2.2", :application=>"app1"}
    instances = [blue_instance, green_instance]

    blue_group= {:name=>"blue", :target_version=>"2.3"}
    green_group= {:name=>"green", :target_version=>"2.4"}
    static_model = [blue_group,green_group]

    environment = 'test_env'
    application = 'app1'
    static_model = [blue_group, green_group]

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(Statuses.new(instances))
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::LiveModelCreator.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application)

    live_model = live_model_creator.create_live_model()

    live_model.instances.size.should eql(2)

    live_model.instances[0].group.name.should eql("blue")
    live_model.instances[1].group.name.should eql("green")
    live_model.instances[0].group.target_version.should eql("2.3")
    live_model.instances[1].group.target_version.should eql("2.4")
  end

  it 'raises an error when there is no cmdb information for the given group' do
    blue_instance = {:group=>"blue", :version=>"2.2", :application=>"app1"}
    green_instance = {:group=>"green", :version=>"2.2", :application=>"app1"}
    instances = [blue_instance, green_instance]

    static_model = []

    environment = 'test_env'
    application = 'app1'
    static_model = []

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(Statuses.new(instances))
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::LiveModelCreator.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application)

    expect {live_model_creator.create_live_model()}.to raise_error(Orc::GroupMissing)
  end

  it 'marks models as failed if a previous action on that model failed' do
    blue_instance = {:group=>"blue", :version=>"2.2", :application=>"app1"}
    green_instance = {:group=>"green", :version=>"2.2", :application=>"app1"}
    instances = [blue_instance, green_instance]

    blue_group= {:name=>"blue", :target_version=>"2.3"}
    green_group= {:name=>"green", :target_version=>"2.4"}
    static_model = [blue_group,green_group]

    environment = 'test_env'
    application = 'app1'
    static_model = [blue_group, green_group]

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(Statuses.new(instances))
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::LiveModelCreator.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application)

    live_model = live_model_creator.create_live_model()
    live_model.instances[0].fail
    live_model2 = live_model_creator.create_live_model()

    live_model2.instances[0].failed?.should == true
  end

  it 'missed messages...' do

  end

end
