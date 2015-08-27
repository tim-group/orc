require 'orc/engine'
require 'orc/factory'

describe Orc::Engine do
  before do
    @remote_client = double(Orc::DeployClient)
  end

  it 'sends a restart message to each given host sequentially' do
    # has to retrieve each host in env/app/group
    # expect remote_client to receive restart call for every host
  end

  it 'does not allow too few instances to participate' do
    # has to call status to find out how many apps are participating
  end

  it 'restarts and reparticipates hosts which are not participating first' do
    # partition hosts by participation
    # invoke restart on non-participating instances first
  end

  it 'halts rolling restart if any individual restart fails' do
    # allow an error to propagate to end the orc process
  end
end
