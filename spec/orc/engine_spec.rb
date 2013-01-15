$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'progress/log'
require 'orc/engine'

class Orc::Engine
  attr_reader :resolution_steps
end

class MockStepEngine < Orc::Engine
  attr_accessor :steps
  def initialize(options)
    super
    @steps = []
  end
  def resolve_one_step
    @steps.shift
  end
  def debug
    false
  end
end

class MockExecuteEngine < Orc::Engine
  attr_accessor :executed
  def initialize(options)
    super
    @executed = []
  end
  def execute_action(action)
    @executed.push action
  end
  def debug
    false
  end
end

describe Orc::Engine do

  def mocklog
    m = double()
    m.stub(:log)
    m.stub(:log_resolution_complete)
    m
  end

  it 'can finish if ok' do
    e = MockStepEngine.new(:application_model => "x", :log => mocklog)
    e.steps = [true]
    e.resolve
  end

  it 'fails to resolve if not ok 100 times' do
      e = MockStepEngine.new(:application_model => "x", :log => mocklog)
      steps = []
      [1..101].each { steps.push(false) }
      e.steps = steps
      expect { e.resolve }.to raise_error(Orc::Exception::FailedToResolve)
   end

   it 'is ok if < 100 steps but then good' do
     e = MockStepEngine.new(:application_model => "x", :log => mocklog )
     steps = []
     [1..90].each { steps.push(false) }
     steps.push(true)
     e.steps = steps
     e.resolve
  end

  def mock_simple_action(ret)
    mock_action = double()
    mock_action.stub(:check_valid).and_return(true)
    mock_action.stub(:execute).and_return(ret)
    mock_action.should_receive(:execute).at_least(:once)
    mock_action
  end

  it 'can execute a success action' do
    e = Orc::Engine.new({:application_model => double(), :log => mocklog})
    e.execute_action mock_simple_action(true)
  end

  it 'gets exception for failed action' do
    e = Orc::Engine.new({:application_model => double(), :log => mocklog})
    expect {
      e.execute_action mock_simple_action(false)
    }.to raise_error(Orc::Exception::FailedToResolve)
  end

  def mock_app_model(resolutions)
    app = double()
    app.stub(:get_resolutions).and_return(resolutions)
    app.should_receive(:get_resolutions).at_least(:once)
    app
  end

  it 'can resolve when no actions needed' do
    log = mocklog
    log.should_receive(:log_resolution_complete).at_least(:once)
    e = MockExecuteEngine.new(:application_model => mock_app_model([]), :log => log)
    e.resolve_one_step.should eql(true)
  end

  it 'should execute an action' do
    e = MockExecuteEngine.new(:application_model => mock_app_model(['moo']), :log => mocklog)
    e.resolve_one_step.should eql(false)
    e.executed.should eql(['moo'])
  end

  it 'should execute first action' do
    e = MockExecuteEngine.new(:application_model => mock_app_model(['moo', 'foo']), :log => mocklog)
    e.resolve_one_step.should eql(false)
    e.executed.should eql(['moo'])
  end


end

