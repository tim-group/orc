$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/model/application'
require 'orc/model/instance'
require 'orc/model/group'

class MockApplicationModel < Orc::Model::Application
  def initialize(args)
    super
    @saved_app_model = args[:stub_app_model]
  end
  def create_live_model
    @saved_app_model
  end
  def instances
    @saved_app_model
  end
end


describe Orc::Model::Application do
  def get_mock_livemodelcreator(args)
    args[:stub_app_model] = [@blue_instance, @green_instance]
    args[:environment] = "latest"
    args[:application] = 'fnar'
    args[:progress_logger] = @progress_logger
    MockApplicationModel.new(args)
  end

  before do
    @progress_logger = double()
    instance = double()
    instance.stub(:host).and_return('Somehost')
    instance.stub(:group_name).and_return('blue')

    @resolution_complete = Orc::Action::ResolvedCompleteAction.new('a', instance)

    @blue_group = Orc::Model::Group.new(:name=>"blue")
    @green_group = Orc::Model::Group.new(:name=>"green")

    @blue_instance = Orc::Model::Instance.new({:group=>"blue"}, @blue_group)
    @green_instance = Orc::Model::Instance.new({:group=>"green"}, @green_group)
    @progress_logger.should_receive(:log).any_number_of_times

    @remote_client = double()
    @cmdb = double()
  end

  it 'gives sensible error message when cmdb info is missing' do
    environment="env"
    application="app_missing"
    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return([])
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(nil)

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Progress.logger(), :mismatch_resolver => double())

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

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(instances)
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Progress.logger(), :mismatch_resolver => double())

    instances = live_model_creator.create_live_model()

    instances.size.should eql(2)

    instances[0].group.name.should eql("blue")
    instances[1].group.name.should eql("green")
    instances[0].group.target_version.should eql("2.3")
    instances[1].group.target_version.should eql("2.4")
  end

  it 'raises an error when there is no cmdb information for the given group' do
    blue_instance = {:group=>"blue", :version=>"2.2", :application=>"app1"}
    green_instance = {:group=>"green", :version=>"2.2", :application=>"app1"}
    instances = [blue_instance, green_instance]

    static_model = []

    environment = 'test_env'
    application = 'app1'
    static_model = []

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(instances)
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Progress.logger(), :mismatch_resolver => double())

    expect {live_model_creator.create_live_model()}.to raise_error(Orc::Exception::GroupMissing)
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

    @remote_client.stub(:status).with(:environment=>environment, :application=>application).and_return(instances)
    @cmdb.stub(:retrieve_application).with(:environment=>environment,:application=>application).and_return(static_model)

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Progress.logger(), :mismatch_resolver => double())

    live_model = live_model_creator.create_live_model()
    #live_model.instances[0].fail
    live_model2 = live_model_creator.create_live_model()

    # FIXME
    #live_model2.instances[0].failed?.should == true
  end

  it 'does nothing if all groups say they are resolved' do
    mock_mismatch_resolver = double()

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(@resolution_complete)
    live_model_creator = get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    @progress_logger.should_receive(:log_resolution_complete)

    live_model_creator.resolve()
  end

  it 'executes proposed actions when required' do
    mock_mismatch_resolver = double()

    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return('foo')
    action.stub(:host).and_return("Somehost")
    action.stub(:group_name).and_return("blue")

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(action,@resolution_complete)
    live_model_creator = get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute)
    @progress_logger.should_receive(:log_resolution_complete)

    live_model_creator.resolve()
  end

  it 'executes actions with higher precedence first' do
    mock_mismatch_resolver = double()

    application = double()

    disable_action = double()
    enable_action = double()
    disable_action.stub(:precedence).and_return(2)
    enable_action.stub(:precedence).and_return(1)
    disable_action.stub(:check_valid).with(anything)
    enable_action.stub(:check_valid).with(anything)
    enable_action.stub(:complete?).and_return(false)
    disable_action.stub(:complete?).and_return(false)
    enable_action.stub(:key).and_return('foo')
    disable_action.stub(:key).and_return('bar')
    disable_action.stub(:host).and_return("Somehost")
    enable_action.stub(:host).and_return("Somehost")
    disable_action.stub(:group_name).and_return("blue")
    enable_action.stub(:group_name).and_return("green")
    disable_action.stub(:failed?).and_return(false)
    enable_action.stub(:failed?).and_return(false)

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(disable_action,disable_action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(enable_action,@resolution_complete,@resolution_complete)

    live_model_creator =  get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    enable_action.should_receive(:execute)
    disable_action.should_receive(:execute)
    @progress_logger.should_receive(:log_resolution_complete)

    live_model_creator.resolve()
  end

  it 'aborts when head action raises an error' do
    mock_mismatch_resolver = double()

    application = double()
    action = double()
    action.stub(:precedence).and_return(2)
    action.stub(:execute).and_raise(Orc::Exception::FailedToResolve.new)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return('foo')
    action.stub(:host).and_return("Somehost")
    action.stub(:group_name).and_return("blue")

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    
    live_model_creator = get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute)

    expect {live_model_creator.resolve()}.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'aborts if it does not resolve after the max loops is hit' do
    mock_mismatch_resolver = double()

    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return({:group => 'green', :host => nil})
    action.stub(:failed?).and_return(true)
    action.stub(:host).and_return("Somehost")
    action.stub(:group_name).and_return("blue")

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    live_model_creator = get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute).at_least(:once)
    expect {live_model_creator.resolve()}.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'if an action fails the instance is marked as failed' do
    mock_mismatch_resolver = double()
    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:execute).and_return(false)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return({:group => 'green', :host => nil})
    action.stub(:failed?).and_return(true)
    action.stub(:host).and_return("Somehost")
    action.stub(:group_name).and_return("blue")

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)

    live_model_creator = get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute).at_least(:once)

    expect {live_model_creator.resolve()}.to raise_error(Orc::Exception::FailedToResolve)
 end

end

