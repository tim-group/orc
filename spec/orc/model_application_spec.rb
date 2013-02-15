$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/model/application'
require 'orc/model/instance'
require 'orc/model/group'
require 'orc/engine'

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
  def get_mock_appmodel(args)
    args[:stub_app_model] = [@blue_instance, @green_instance]
    args[:environment] = "latest"
    args[:application] = 'fnar'
    args[:progress_logger] = @progress_logger
    args[:remote_client] = double()
    MockApplicationModel.new(args)
  end
  def get_mock_engine(args)
    Orc::Engine.new(
      :application_model => get_mock_appmodel(args),
      :log => @progress_logger
    )
  end

  before do
    @progress_logger = double()
    instance = double()
    instance.stub(:host).and_return('Somehost')
    instance.stub(:group_name).and_return('blue')
    instance.stub(:key).and_return({:host => 'Somehost', :group => 'blue'})

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

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Orc::Progress.logger(), :mismatch_resolver => double())

    expect {
      live_model = live_model_creator.create_live_model()
    }.to raise_error(Orc::CMDB::ApplicationMissing)
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

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Orc::Progress.logger(), :mismatch_resolver => double())

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

    live_model_creator = Orc::Model::Application.new(:remote_client=>@remote_client, :cmdb=>@cmdb, :environment=>environment, :application=>application, :progress_logger => Orc::Progress.logger(), :mismatch_resolver => double())

    expect {live_model_creator.create_live_model()}.to raise_error(Orc::Exception::GroupMissing)
  end

  it 'does nothing if all groups say they are resolved' do
    mock_mismatch_resolver = double()

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(@resolution_complete)
    engine = get_mock_engine({:mismatch_resolver=>mock_mismatch_resolver})

    @progress_logger.should_receive(:log_resolution_complete)

    engine.resolve()
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
    action.stub(:execute).and_return(true)

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(action,@resolution_complete)
    engine = get_mock_engine({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute)
    @progress_logger.should_receive(:log_resolution_complete)

    engine.resolve()
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
    disable_action.stub(:execute).and_return(true)
    enable_action.stub(:execute).and_return(true)

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(disable_action,disable_action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(enable_action,@resolution_complete,@resolution_complete)

    engine = get_mock_engine({:mismatch_resolver=>mock_mismatch_resolver})

    enable_action.should_receive(:execute)
    disable_action.should_receive(:execute)
    @progress_logger.should_receive(:log_resolution_complete)

    engine.resolve()
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

    engine = get_mock_engine({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute)
    expect {engine.resolve()}.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'will not run actions which are invalid' do
    mock_mismatch_resolver = double()

    application = double()
    paction = double()
    naction = double() # [@blue_instance, @green_instance]
    actions = [paction, naction]
    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(paction)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(naction)
    paction.stub(:precedence).and_return(2)
    naction.stub(:precedence).and_return(2)
    paction.stub(:host).and_return('host1')
    naction.stub(:host).and_return('host2')
    paction.stub(:execute).and_raise(Orc::Exception::FailedToResolve.new)
    paction.stub(:check_valid).and_raise(Orc::Exception::FailedToResolve.new)
    naction.stub(:check_valid).with(anything)
    naction.stub(:execute).and_return(true)
    [naction, paction].each do |action|
      action.stub(:complete?).and_return(false)
      action.stub(:key).and_return('foo')
      action.stub(:group_name).and_return("blue")
    end

    model = get_mock_appmodel({:mismatch_resolver=>mock_mismatch_resolver})

    model.get_resolutions.should eql([naction])
  end

  it 'aborts if there are actions, but all actions are invalid' do
    mock_mismatch_resolver = double()

    application = double()
    action = double()
    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    action.stub(:precedence).and_return(2)
    action.stub(:execute).and_raise(Orc::Exception::FailedToResolve.new)
    action.stub(:check_valid).and_raise(Orc::Exception::FailedToResolve.new)
    action.stub(:complete?).and_return(false)
      action.stub(:key).and_return('foo')
      action.stub(:group_name).and_return("blue")

    model = get_mock_appmodel({:mismatch_resolver=>mock_mismatch_resolver})

    expect { model.get_resolutions}.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'aborts if it does not resolve after the max loops is hit' do
    mock_mismatch_resolver = double()

    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return({:group => 'green', :host => nil})
    action.stub(:host).and_return("Somehost")
    action.stub(:group_name).and_return("blue")
    action.stub(:execute).and_return(true)

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    engine = get_mock_engine({:mismatch_resolver=>mock_mismatch_resolver})

    action.should_receive(:execute).at_least(:once)
    expect {engine.resolve()}.to raise_error(Orc::Exception::FailedToResolve)
  end

end
