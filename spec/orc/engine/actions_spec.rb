require 'orc/engine/actions'

class Orc::Engine::Action::WaitActionBase
  attr_accessor :max_wait
end

describe Orc::Engine::Action::WaitActionBase do
  it 'wait action can timeout on itself and others' do
    group = double
    allow(group).to receive(:name).and_return('blue')
    instance = double
    allow(instance).to receive(:group).and_return(group)
    allow(instance).to receive(:host).and_return('localhost')
    i = Orc::Engine::Action::WaitActionBase.new('fo', instance)
    i.do_execute([i])
    sleep 1
    i.max_wait = 0
    expect { i.do_execute([i]) }.to raise_error(Orc::Exception::Timeout)
    new = Orc::Engine::Action::WaitActionBase.new('fo', instance)
    multi = [i, new]
    new.max_wait = 0
    expect { new.do_execute(multi) }.to raise_error(Orc::Exception::Timeout)
  end
end
