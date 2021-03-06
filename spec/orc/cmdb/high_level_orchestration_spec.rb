require 'orc/cmdb/high_level_orchestration'

def create_high_level_orchestration(cmdb, git, logger)
  Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => cmdb,
    :git => git,
    :environment => 'test_env',
    :application => 'ExampleApp',
    :logger => logger)
end

describe Orc::CMDB::HighLevelOrchestration do
  before do
    @cmdb = double
    @git = double
    @logger = double
    @high_level_orchestration = create_high_level_orchestration(@cmdb, @git, @logger)
  end

  it 'install saves the requested version to the all group group if participation is true and all groups have ' \
     'never_swap' do
    cmdb_yaml = [
      { :name                => 'grey',
        :target_version       => '1',
        :target_participation => true,
        :never_swap           => true },
      { :name                => 'blue',
        :target_version       => '1',
        :target_participation => true,
        :never_swap           => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name                => 'grey',
                                                         :target_version       => '2',
                                                         :target_participation => true,
                                                         :never_swap           => true },
                                                       { :name                => 'blue',
                                                         :target_version       => '2',
                                                         :target_participation => true,
                                                         :never_swap           => true }
                                                     ])

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.install('2', 'all')
  end

  it 'install saves the requested version to the specified group if participation is true and all groups have ' \
     'never_swap' do
    cmdb_yaml = [
      { :name                => 'grey',
        :target_version       => '1',
        :target_participation => true,
        :never_swap           => true },
      { :name                => 'blue',
        :target_version       => '1',
        :target_participation => true,
        :never_swap           => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name                => 'grey',
                                                         :target_version       => '2',
                                                         :target_participation => true,
                                                         :never_swap           => true },
                                                       { :name                => 'blue',
                                                         :target_version       => '1',
                                                         :target_participation => true,
                                                         :never_swap           => true }
                                                     ])

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.install('2', 'grey')
  end

  it 'install saves the requested version to the specified group if participation is false' do
    cmdb_yaml = [
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false },
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'grey',
                                                         :target_version => '2',
                                                         :target_participation => false },

                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => true }
                                                     ])

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.install('2', 'grey')
  end

  it 'install saves the requested version in all groups if there is only one swappable one' do
    cmdb_yaml = [
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true },

      { :name => 'blue',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'grey',
                                                         :target_version => '2',
                                                         :target_participation => false,
                                                         :never_swap => true },

                                                       { :name => 'blue',
                                                         :target_version => '2',
                                                         :target_participation => true }
                                                     ])

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered

    @high_level_orchestration.install('2')
  end

  it 'install saves the requested version in the currently offline group' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '2',
                                                         :target_participation => false },

                                                       { :name => 'grey',
                                                         :target_version => '2',
                                                         :target_participation => false },

                                                       { :name => 'green',
                                                         :target_version => '1',
                                                         :target_participation => true }
                                                     ]
                                                    )
    expect(@logger).to receive(:log).with("Not installing to group green - consider setting never_swap")
    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.install('2')
  end

  it 'install fails if attempting to change version of a group that is swappable and participating but has no '\
      'group to swap with' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true,
        :never_swap => false },
      { :name => 'green',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => true,
                                                         :never_swap => false },
                                                       { :name => 'green',
                                                         :target_version => '1',
                                                         :target_participation => false,
                                                         :never_swap => true }
                                                     ]
                                                    )
    expect(@logger).to receive(:log).with("Refusing to install: version: '2' for group: 'blue'. "\
                                          "Application: 'ExampleApp', environment: 'test_env'\n"\
                                          "Group 'blue' is the only swappable group (never_swap=false)\n"\
                                          "In order to install a new version using swap, "\
                                          "a minimum of 2 swappable groups are required")

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.install('2', 'blue')
  end

  it 'swap does nothing if there is only one swappable group' do
    cmdb_yaml = [
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true },
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'grey',
                                                         :target_version => '1',
                                                         :target_participation => false,
                                                         :never_swap => true
                                                       },
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => true }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.swap
  end

  it 'swap still does nothing regardless of the order of groups definition with one swappable and one non-swappable ' \
     'group' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => true },
                                                       { :name => 'grey',
                                                         :target_version => '1',
                                                         :target_participation => false,
                                                         :never_swap => true }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.swap
  end

  it 'swap does nothing when only 1 non-swappable group even if it is not participating' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => false }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.swap
  end

  it 'swap makes the currently offline group online and vice versa' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '1',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => true },

                                                       { :name => 'green',
                                                         :target_version => '1',
                                                         :target_participation => false },

                                                       { :name => 'grey',
                                                         :target_version => '1',
                                                         :target_participation => false,
                                                         :never_swap => true
                                                       }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.swap
  end

  it 'deploy does an install followed by a swap' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '2',
                                                         :target_participation => true },
                                                       { :name => 'green',
                                                         :target_version => '1',
                                                         :target_participation => false }
                                                     ]
                                                    )
    expect(@logger).to receive(:log).with("Not installing to group green - consider setting never_swap")
    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.deploy('2')
  end

  it 'deploy when only one group just upgrades the version' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '2',
                                                         :target_participation => true }]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.deploy('2')
  end

  it 'promotes an application from one environment to another' do
    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
      :cmdb => @cmdb,
      :git => @git,
      :environment => "env2",
      :application => 'ExampleApp')

    cmdb_env1_yaml = [
      { :name => 'blue',
        :target_version => '2',
        :target_participation => true }
    ]
    cmdb_env2_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true }
    ]
    expect(@git).to receive(:update).ordered
    allow(@cmdb).to receive(:retrieve_application).with(:environment => "env2", :application => 'ExampleApp').
      and_return(cmdb_env2_yaml)

    allow(@cmdb).to receive(:retrieve_application).with(:environment => "env1", :application => 'ExampleApp').
      and_return(cmdb_env1_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => "env2", :application => 'ExampleApp' },
                                                     [{
                                                       :target_participation => true,
                                                       :target_version => "2",
                                                       :name => "blue" }])
    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered

    high_level_orchestration.promote_from_environment('env1')
  end

  it 'installs limited to one group with minimum version' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => true },
      { :name => 'green',
        :target_version => '2',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '3',
        :target_participation => true
      }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '4',
                                                         :target_participation => true },

                                                       { :name => 'green',
                                                         :target_version => '2',
                                                         :target_participation => true },

                                                       { :name => 'grey',
                                                         :target_version => '3',
                                                         :target_participation => true
                                                       }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.limited_install('4')
  end

  it 'installs limited to one group with minimum version handling dotted version numbers' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1.0.99',
        :target_participation => true },
      { :name => 'green',
        :target_version => '1.0.100',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1.0.98',
        :target_participation => true
      }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1.0.99',
                                                         :target_participation => true },

                                                       { :name => 'green',
                                                         :target_version => '1.0.100',
                                                         :target_participation => true },

                                                       { :name => 'grey',
                                                         :target_version => '1.0.101',
                                                         :target_participation => true
                                                       }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.limited_install('1.0.101')
  end

  it 'deploys to all machines in all groups except the group that is swapped' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '2',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '3',
                                                         :target_participation => true },

                                                       { :name => 'green',
                                                         :target_version => '2',
                                                         :target_participation => false },

                                                       { :name => 'grey',
                                                         :target_version => '3',
                                                         :target_participation => false,
                                                         :never_swap => true
                                                       }
                                                     ]
                                                    )
    expect(@logger).to receive(:log).with("Not installing to group green - consider setting never_swap")
    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.deploy('3')
  end

  it 'deploys to to the machines in the specified groups' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '2',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '3',
                                                         :target_participation => true },

                                                       { :name => 'green',
                                                         :target_version => '2',
                                                         :target_participation => false },

                                                       { :name => 'grey',
                                                         :target_version => '1',
                                                         :target_participation => false,
                                                         :never_swap => true
                                                       }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.deploy('3', 'blue')
  end

  it 'does no swapping if told to deploy to a group that is not swappable' do
    cmdb_yaml = [
      { :name => 'blue',
        :target_version => '1',
        :target_participation => false },
      { :name => 'green',
        :target_version => '2',
        :target_participation => true },
      { :name => 'grey',
        :target_version => '1',
        :target_participation => false,
        :never_swap => true }
    ]

    allow(@cmdb).to receive(:retrieve_application).with(:environment => 'test_env', :application => 'ExampleApp').
      and_return(cmdb_yaml)

    expect(@cmdb).to receive(:save_application).with({ :environment => 'test_env', :application => 'ExampleApp' },
                                                     [
                                                       { :name => 'blue',
                                                         :target_version => '1',
                                                         :target_participation => false },

                                                       { :name => 'green',
                                                         :target_version => '2',
                                                         :target_participation => true },

                                                       { :name => 'grey',
                                                         :target_version => '3',
                                                         :target_participation => false,
                                                         :never_swap => true
                                                       }
                                                     ]
                                                    )

    expect(@git).to receive(:update).ordered
    expect(@git).to receive(:commit_and_push).ordered
    @high_level_orchestration.deploy('3', 'grey')
  end
end
