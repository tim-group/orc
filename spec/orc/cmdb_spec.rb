require 'orc/cmdb/yaml'

describe Orc::CMDB::Yaml do
  it 'retrieves list of groups, with target versions and target_participation' do
    cmdb =  Orc::CMDB::Yaml.new(:data_dir => "spec/fixtures/cmdb/")
    group_static_models = cmdb.retrieve_application(:environment => "cmdb_test", :application => "testx")
    group_static_models.size.should eql(2)

    group_static_models[0][:name].should eql("blue")
    group_static_models[0][:target_version].should eql("2.2")
    group_static_models[0][:target_participation].should eql(false)

    group_static_models[1][:name].should eql("green")
    group_static_models[1][:target_version].should eql("2.3")
    group_static_models[1][:target_participation].should eql(true)
  end

  it 'saves list of groups, with target_version and participation to a new yaml file' do
    cmdb =  Orc::CMDB::Yaml.new(:data_dir => "spec/fixtures/cmdb/")
    group_static_models = cmdb.retrieve_application(:environment => "cmdb_test", :application => "testx")
    group_static_models[1][:target_version] = "77"
    group_static_models[1][:target_participation] = false

    rand_num = (rand * 1000).ceil
    Dir.mkdir("build/") unless File.directory? "build/"
    cmdb =  Orc::CMDB::Yaml.new(:data_dir => "build/")
    env = "cmdb_test_#{rand_num}"
    Dir.mkdir("build/#{env}") # XXX: got File exists, files are never removed, rand() above has small range
    cmdb.save_application({ :environment => env, :application => "testx" }, group_static_models)
    group_static_models_again = cmdb.retrieve_application(:environment => "cmdb_test_#{rand_num}",
                                                          :application => "testx")

    group_static_models_again[1][:target_version].should eql("77")
    group_static_models_again[1][:target_participation].should eql(false)
  end

  it 'saves list of groups, with target_version and participation to an existing yaml file' do
    rand_num = (rand * 1000).ceil

    yaml_content = {
      'testfred' => [
        {
          :target_version => "1",
          :name => 'blue',
          :target_participation => false },
        {
          :target_version => "2",
          :name => "green",
          :target_participation => false }
      ],
      'testbob' => [
        {
          :target_version => "3",
          :name => 'blue',
          :target_participation => false },
        {
          :target_version => "4",
          :name => "green",
          :target_participation => false }
      ]

    }
    group_static_models = [
      {
        :target_version => "1",
        :name => "blue",
        :target_participation => false
      },
      {
        :target_version => "77",
        :name => "green",
        :target_participation => false
      }
    ]

    Dir.mkdir("build/") unless File.directory? "build/"
    testdir = "build/cmdb_test_#{rand_num}"
    Dir.mkdir testdir if !Pathname.new(testdir).exist?
    File.open("#{testdir}/testfred.yaml", "w") do |f|
      f.write(yaml_content["testfred"].to_yaml)
    end
    File.open("#{testdir}/testbob.yaml", "w") do |f|
      f.write(yaml_content["testbob"].to_yaml)
    end

    cmdb =  Orc::CMDB::Yaml.new(:data_dir => "build/")
    cmdb.save_application({ :environment => "cmdb_test_#{rand_num}", :application => "testx" }, group_static_models)

    group_static_models_again = cmdb.retrieve_application(:environment => "cmdb_test_#{rand_num}",
                                                          :application => "testx")
    group_static_models_again[1][:target_version].should eql("77")
    group_static_models_again[1][:target_participation].should eql(false)

    group_static_models_again = cmdb.retrieve_application(:environment => "cmdb_test_#{rand_num}",
                                                          :application => "testbob")
    group_static_models_again[1][:target_version].should eql("4")
    group_static_models_again[1][:target_participation].should eql(false)
  end
end
