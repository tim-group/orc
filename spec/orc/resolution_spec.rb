require 'orc/factory'
require 'orc/testutil/in_memory_cmdb'
require 'orc/testutil/fake_remote_client'

describe Orc::Engine do
  it 'vanilla pass through' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(
                                 :groups => {
                                   "a-app" => [{
                                     :name => "blue",
                                     :target_participation => true,
                                     :target_version => "5"
                                   }]
                                 }))

    expect(factory.engine.resolve).to eq ['DisableParticipationAction: on h1 blue',
                                          'UpdateVersionAction: on h1 blue',
                                          'EnableParticipationAction: on h1 blue',
                                          'DisableParticipationAction: on h2 blue',
                                          'UpdateVersionAction: on h2 blue',
                                          'EnableParticipationAction: on h2 blue']
  end

  it 'safely deploys across multiple clusters' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-2",
                                   :host => "h3",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => true,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::FailedToResolve)
  end

  xit 'safely deploys across multiple clusters and app types' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-2",
                                   :host => "h3",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-2",
                                   :host => "h4",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => true,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'safely deploys across multiple clusters and app types' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-1",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-2",
                                   :host => "h3",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :cluster => "app-2",
                                   :host => "h4",
                                   :version => "2.2",
                                   :application => "app-2",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => true,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'gives sensible error messages when cmdb info is missing' do
    factory = Orc::Factory.new({ :environment => "a", :application => "non-existent-app" },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "non-existent-app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "non-existent-app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {}))

    expect { factory.engine.resolve }.to raise_error(Orc::CMDB::ApplicationMissing)
  end

  it 'raises an error when there is no cmdb information for the given group' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app" },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :host => "h2",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => []
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::GroupMissing)
  end

  it 'does nothing if all groups say they are resolved' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "5",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 { :group => "blue",
                                   :host => "h2",
                                   :version => "5",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => true,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect(factory.engine.resolve).to eq []
  end

  it 'will fail - if there is one instance and the next action is to remove it' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => true,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'aborts if the same action is attempted twice - ie fails to deploy' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => FakeRemoteClient.new(:fail_to_deploy => true, :instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "2.2",
                                   :application => "app",
                                   :participating => false,
                                   :health        => "healthy" }]),
                               :cmdb => InMemoryCmdb.new(:groups => {
                                                           "a-app" => [{
                                                             :name => "blue",
                                                             :target_participation => false,
                                                             :target_version => "5"
                                                           }]
                                                         }))

    expect { factory.engine.resolve }.to raise_error(Orc::Exception::FailedToResolve)
  end
end
