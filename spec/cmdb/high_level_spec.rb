require 'rubygems'
require 'rspec'
require 'cmdb/high_level_orchestration'

describe CMDB::HighLevelOrchrestration do
  before do
    @cmdb = double()
    @git = double()
  end

  it 'install saves the requested version in the currently offline group' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orcestration = CMDB::HighLevelOrchrestration.new(
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

      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orcestration.install('2')
  end

  it 'swap makes the currently offline group online and vice versa' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> false},
      {:name=> 'green',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orcestration = CMDB::HighLevelOrchrestration.new(
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
      :target_participation=> false}
    ]
    )

    @git.should_receive(:update).ordered
    @git.should_receive(:commit_and_push).ordered
    high_level_orcestration.swap()
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

    high_level_orcestration = CMDB::HighLevelOrchrestration.new(
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
    high_level_orcestration.deploy('2')
  end
  it 'deploy when only one group just upgrades the version' do
    cmdb_yaml = [
      {:name=> 'blue',
      :target_version=> '1',
      :target_participation=> true}
    ]

    high_level_orcestration = CMDB::HighLevelOrchrestration.new(
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
    high_level_orcestration.deploy('2')
  end

  it 'promotes an application from one environment to another' do
    high_level_orcestration = CMDB::HighLevelOrchrestration.new(
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

    high_level_orcestration.promote_from_environment('env1')
 end

end
