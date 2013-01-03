$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/engine'
require 'model/instance_model'
require 'model/group_model'
require 'orc/live_model_creator'

class MockLiveModelCreator < Orc::LiveModelCreator
  def initialize(args)
    super
    @saved_app_model = args[:stub_app_model]
  end
  def create_live_model
    self
  end
  def instances
    @saved_app_model
  end
end

describe Orc::Engine do

  def get_mock_livemodelcreator(args)
    args[:stub_app_model] = [@blue_instance, @green_instance]
    args[:environment] = "latest"
    args[:application] = 'fnar'
    args[:progress_logger] = @progress_logger
    MockLiveModelCreator.new(args)
  end

  before do
    @progress_logger = double()
    @resolution_complete = Orc::Action::ResolvedCompleteAction.new('a', 'b')

    @blue_group = Model::GroupModel.new(:name=>"blue")
    @green_group = Model::GroupModel.new(:name=>"green")

    @blue_instance = Model::InstanceModel.new({:group=>"blue"}, @blue_group)
    @green_instance = Model::InstanceModel.new({:group=>"green"}, @green_group)
    @progress_logger.should_receive(:log).any_number_of_times

  end

  it 'does nothing if all groups say they are resolved' do
    mock_mismatch_resolver = double()

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(@resolution_complete)
    engine = Orc::Engine.new(
      :progress_logger => @progress_logger,
      :live_model_creator=> get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
      :mismatch_resolver=>mock_mismatch_resolver
    )

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

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(action,@resolution_complete)
    engine = Orc::Engine.new(
      :progress_logger => @progress_logger,
      :live_model_creator=>get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
      :mismatch_resolver=>mock_mismatch_resolver
    )

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

    mock_mismatch_resolver.stub(:resolve).with(@blue_instance).and_return(disable_action,disable_action,@resolution_complete)
    mock_mismatch_resolver.stub(:resolve).with(@green_instance).and_return(enable_action,@resolution_complete,@resolution_complete)

    engine = Orc::Engine.new(
    :progress_logger => @progress_logger,
    :live_model_creator=>get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
    :mismatch_resolver=>mock_mismatch_resolver)

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
    action.stub(:execute).and_raise(Orc::FailedToResolve.new)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return('foo')

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    engine = Orc::Engine.new(
      :progress_logger => @progress_logger,
      :live_model_creator=>get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
      :mismatch_resolver=>mock_mismatch_resolver
    )

    action.should_receive(:execute)

    expect {engine.resolve()}.to raise_error(Orc::FailedToResolve)
  end

  it 'aborts if it does not resolve after the max loops is hit' do
    mock_mismatch_resolver = double()

    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return('foo')
    action.stub(:failed?).and_return(true)

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)
    engine = Orc::Engine.new(
      :progress_logger => @progress_logger,
      :live_model_creator=>get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
      :mismatch_resolver=>mock_mismatch_resolver
    )

    action.should_receive(:execute).at_least(:once)
    expect {engine.resolve()}.to raise_error(Orc::FailedToResolve)
  end

  it 'if an action fails the instance is marked as failed' do
    mock_mismatch_resolver = double()
    action = double()
    action.stub(:precedence).and_return(999)
    action.stub(:check_valid).with(anything)
    action.stub(:execute).and_return(false)
    action.stub(:complete?).and_return(false)
    action.stub(:key).and_return('bar')
    action.stub(:failed?).and_return(true)

    mock_mismatch_resolver.stub(:resolve).with(anything).and_return(action)

    engine = Orc::Engine.new(
      :progress_logger => @progress_logger,
      :live_model_creator=>get_mock_livemodelcreator({:mismatch_resolver=>mock_mismatch_resolver}),
      :mismatch_resolver=>mock_mismatch_resolver
    )

    action.should_receive(:execute).at_least(:once)

    expect {engine.resolve()}.to raise_error(Orc::FailedToResolve)
 end

end

