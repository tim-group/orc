$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'progress/log'
require 'orc/engine'

class MockStepEngine < Orc::Engine
  attr_accessor :steps
  def initialize(options)
    super
    @steps = []
  end
  def resolve_one_step
    @steps.shift
  end
end

describe Orc::Engine do

  it 'can finish if ok' do
    e = MockStepEngine.new(:application_model => "x", :log => Progress.logger)
    e.steps = [true]
    e.resolve
  end

  it 'fails to resolve if not ok 100 times' do
      e = MockStepEngine.new(:application_model => "x", :log => Progress.logger)
      steps = []
      [1..101].each { steps.push(false) }
      e.steps = steps
      expect { e.resolve }.to raise_error(Orc::Exception::FailedToResolve)
   end

   it 'is ok if < 100 steps but then good' do
     e = MockStepEngine.new(:application_model => "x", :log => Progress.logger )
     steps = []
     [1..90].each { steps.push(false) }
     steps.push(true)
     e.steps = steps
     e.resolve
  end
end

