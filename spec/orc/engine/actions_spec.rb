require 'orc/engine/actions'

class Orc::Engine::Action::WaitActionBase
  attr_accessor :max_wait
end

describe Orc::Engine::Action::WaitActionBase do
  it 'wait action can timeout on itself' do
    instance = make_instance_double
    wait_action = Orc::Engine::Action::WaitActionBase.new(:remote_client => nil, :instance => instance, :max_wait => 1)
    wait_action.do_execute([wait_action])
    sleep 2
    expect { wait_action.do_execute([wait_action]) }.to raise_error(Orc::Engine::Timeout)
  end

  it 'will raise a timeout while executing other actions' do
    instance = make_instance_double
    high_tolerance_wait = Orc::Engine::Action::WaitActionBase.new(
      :remote_client => nil,
      :instance => instance,
      :max_wait => 1000)
    low_tolerance_wait = Orc::Engine::Action::WaitActionBase.new(
      :remote_client => nil,
      :instance => instance,
      :max_wait => 0)
    multi = [high_tolerance_wait, low_tolerance_wait]
    sleep 1
    expect { low_tolerance_wait.do_execute(multi) }.to raise_error(Orc::Engine::Timeout)
  end

  private

  def make_instance_double
    group = double
    allow(group).to receive(:name).and_return('blue')
    instance = double
    allow(instance).to receive(:group).and_return(group)
    allow(instance).to receive(:host).and_return('localhost')
    instance
  end
end
