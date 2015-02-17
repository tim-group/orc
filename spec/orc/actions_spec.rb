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
