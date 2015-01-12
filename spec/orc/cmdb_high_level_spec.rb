require 'rubygems'
require 'rspec'
require 'orc/cmdb/high_level_orchestration'

describe Orc::CMDB::HighLevelOrchestration do
  before do
    @cmdb = double()
    @git = double()
  end

  it 'install saves the requested version to the specified group' do
    cmdb_yaml = [
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false,
      :never_swap => true},

      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'grey',
      :target_version=> '2',
      :target_participation=> false,
      :never_swap => true},

      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
   ])

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.install('2', ['grey'])
  end

  it 'install saves the requested version in all groups if there is only one swappable one' do
    cmdb_yaml = [
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false,
      :never_swap => true},

      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'grey',
      :target_version=> '2',
      :target_participation=> false,
      :never_swap => true},

      {:name=> 'blue',
      :target_version=> '2',
      :target_participation=> true}
   ])

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.install('2')
  end


  it 'install saves the requested version in the currently offline group' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false},
       {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '2',
      :target_participation=> false},

      {:name=> 'grey',
      :target_version=> '2',
      :target_participation=> false},


      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.install('2')
  end

  it 'wont do anything if there is only one swappable group' do
    cmdb_yaml = [
     {:name=> 'grey',
      :target_version=> '1',
      :target_participation => false,
      :never_swap => true},
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true},
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false,
      :never_swap => true
      },
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.swap()
  end


  it 'swap still does nothing regardless of the order of groups definitation with one swappable and one non-swapple group' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true},
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation => false,
      :never_swap => true},
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true},
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false,
      :never_swap => true },
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.swap()
  end


  it 'swap does nothing when only 1 non-swappable group even if it is not participating' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation => false }
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.swap()
  end

  it 'swap makes the currently offline group online and vice versa' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true},
      {:name=> 'grey',
      :target_version=> '1',
      :target_participation => false,
      :never_swap => true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true},

      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> false},

      {:name=> 'grey',
      :target_version=> '1',
      :target_participation=> false,
      :never_swap => true
      }
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.swap()
  end

  it 'deploy does an install followed by a swap' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '2',
      :target_participation=> true},
      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> false}
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.deploy('2')
  end
  it 'deploy when only one group just upgrades the version' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"test_env",
    :application=>"ExampleApp")

    @cmdb.stub(:retrieve_application).with({:environment=>"test_env", :application=>"ExampleApp"}).and_return(cmdb_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"test_env", :application=>"ExampleApp"},
    [
      {:name=> 'blue',
      :target_version=> '2',
      :target_participation=> true}    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orchestration.deploy('2')
  end

  it 'promotes an application from one environment to another' do
    high_level_orchestration = Orc::CMDB::HighLevelOrchestration.new(
    :cmdb => @cmdb,
    :git => @git,
    :environment=>"env2",
    :application=>"ExampleApp")

   cmdb_env1_yaml = [
      {:name=> 'blue',
      :target_version=> '2',
      :target_participation=> true}
    ]
    cmdb_env2_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]
    @git.should_receive(:update).ordered
     @cmdb.stub(:retrieve_application).with({:environment=>"env2", :application=>"ExampleApp"}).and_return(cmdb_env2_yaml)

     @cmdb.stub(:retrieve_application).with({:environment=>"env1", :application=>"ExampleApp"}).and_return(cmdb_env1_yaml)

    @cmdb.should_receive(:save_application).with({:environment=>"env2", :application=>"ExampleApp"},
    [{
        :target_participation=> true,
        :target_version=> "2",
        :name=> "blue"}])
    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered

    high_level_orchestration.promote_from_environment('env1')
 end

end
