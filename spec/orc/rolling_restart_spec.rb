require 'orc/engine'
require 'orc/factory'

describe Orc::Engine do
  it 'sends a restart message to each given host sequentially' do
    # has to retrieve each host in env/app/group
    # expect remote_client to receive restart call for every host
  end

  it 'does not allow too few instances to participate' do
    # has to call status to find out how many apps are participating
  end

  it 'restarts and reparticipates hosts which are not participating first' do
    # TODO: discuss with Michal whether we want this behaviour or just fail if the apps need resolved
    # partition hosts by participation
    # invoke restart on non-participating instances first
  end

  xit 'fails with an error message if the application group is not in the expected state' do
    app_in_unresolved_state = {
      :group => "blue",
      :host => "h2",
      :version => "4",
      :application => "app",
      :participating => true,
      :health        => "healthy"
    }
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 },
                               :remote_client => remote_client(:instances => [
                                 { :group => "blue",
                                   :host => "h1",
                                   :version => "5",
                                   :application => "app",
                                   :participating => true,
                                   :health        => "healthy" },
                                 app_in_unresolved_state]),
                               :cmdb => fake_cmdb(:groups => {
                                                    "a-app" => [{
                                                      :name => "blue",
                                                      :target_participation => true,
                                                      :target_version => "5"
                                                    }]
                                                  }))

    expect { factory.engine.rolling_restart }.to raise_error(Orc::Exception::CannotRestartUnresolvedGroup)
  end

  it 'halts rolling restart if any individual restart fails' do
    # allow an error to propagate to end the orc process
  end
end
