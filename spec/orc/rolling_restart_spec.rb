require 'orc/engine'
require 'orc/factory'
require 'orc/testutil/in_memory_cmdb'
require 'orc/testutil/fake_remote_client'

describe Orc::Engine do
  xit 'sends a restart message to each given host sequentially' do
    factory = Orc::Factory.new({ :environment => 'a', :application => 'app', :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => 'blue',
                                   :host => 'h1',
                                   :version => '5',
                                   :application => 'app',
                                   :participating => true,
                                   :health        => 'healthy' },
                                 { :group => 'blue',
                                   :host => 'h2',
                                   :version => '5',
                                   :application => 'app',
                                   :participating => true,
                                   :health        => 'healthy' }]),
                               :cmdb => InMemoryCmdb.new(
                                 :groups => {
                                   'a-app' => [{
                                     :name => 'blue',
                                     :target_participation => true,
                                     :target_version => '5'
                                   }]
                                 }))

    expect(factory.engine.rolling_restart).to eql ['DisableParticipationAction: on h1 blue',
                                                   'RestartAction: on h1 blue',
                                                   'EnableParticipationAction: on h1 blue',
                                                   'DisableParticipationAction: on h2 blue',
                                                   'RestartAction: on h2 blue',
                                                   'EnableParticipationAction: on h2 blue']
  end

  it 'does not allow too few instances to participate' do
    # has to call status to find out how many apps are participating
  end

  it 'restarts and reparticipates hosts which are not participating first' do
    # TODO: discuss with Michal whether we want this behaviour or just fail if the apps need resolved
    # partition hosts by participation
    # invoke restart on non-participating instances first
  end

  it 'fails with an error message if the application group is not in the expected state' do
    app_in_unresolved_state = {
      :group => 'blue',
      :host => 'h2',
      :version => '4',
      :application => 'app',
      :participating => true,
      :health        => 'healthy'
    }
    factory = Orc::Factory.new({ :environment => 'a', :application => 'app', :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => 'blue',
                                   :host => 'h1',
                                   :version => '5',
                                   :application => 'app',
                                   :participating => true,
                                   :health        => 'healthy' },
                                 app_in_unresolved_state]),
                               :cmdb => InMemoryCmdb.new(
                                 :groups => {
                                   'a-app' => [{
                                     :name => 'blue',
                                     :target_participation => true,
                                     :target_version => '5'
                                   }]
                                 }))

    expect { factory.engine.rolling_restart }.to raise_error(Orc::Exception::CannotRestartUnresolvedGroup)
  end

  it 'halts rolling restart if any individual restart fails' do
    # allow an error to propagate to end the orc process
  end
end
