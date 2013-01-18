$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/actions'

class Orc::Action::WaitActionBase
  attr_accessor :max_wait
end

describe Orc::Action::WaitActionBase do

  it 'wait action can timeout on itself and others' do
    group = double()
    group.stub(:name).and_return('blue');
    instance = double()
    instance.stub(:group).and_return(group)
    instance.stub(:host).and_return('localhost')
    i = Orc::Action::WaitActionBase.new('fo', instance)
    i.do_execute([i])
    sleep 1
    i.max_wait = 0
    expect { i.do_execute([i]) }.to raise_error(Orc::Exception::Timeout)
    new = Orc::Action::WaitActionBase.new('fo', instance)
    multi = [i, new]
    new.max_wait = 0
    expect { new.do_execute(multi) }.to raise_error(Orc::Exception::Timeout)
  end
end

describe Orc::Action::UpdateVersionAction do
  def get_testaction(group='A')
    group = double()
    group.stub(:name).and_return(group)
    group.stub(:target_version).and_return(1.1)
    instance = double()
    instance.stub(:group).and_return(group)
    instance.stub(:host).and_return('localhost')
    remote_client = double()
    remote_client.stub(:update_to_version).and_return(true)
    Orc::Action::UpdateVersionAction.new(remote_client, instance)
  end

  it 'works as expected' do
    i = get_testaction
    i.do_execute([i]).should eql(true)
  end

  it 'works as expected for two actions in turn in different groups' do
    first = get_testaction()
    second = get_testaction('B')
    second.do_execute([first, second]).should eql(true)
  end

  it 'throws an exception if the same action for the same group is run twice' do
    first = get_testaction()
    second = get_testaction()
    expect { second.do_execute([first, second]) }.to raise(Orc::Exception::FailedToResolve)
  end
end

