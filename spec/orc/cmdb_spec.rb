require 'rubygems'
require 'rspec'
require 'orc/cmdb/yaml'
require 'yaml'

describe Orc::CMDB::Yaml do
  before do
    # write out cmdb
    #    File.open('README')
    readme = YAML::load("
-
  name: blue
  target_version: 2.2
  targer_participation: false
-
  name: green
  target_version: 2.3
  targer_participation: true
")

  end

  it 'retrieves list of groups, with target versions and target_participation' do
    cmdb =  Orc::CMDB::Yaml.new(:data_dir=>"spec/fixtures/cmdb/")
    group_static_models = cmdb.retrieve_application(:environment=>"cmdb_test", :application=>"testx")
    group_static_models.size().should eql(2)

    group_static_models[0][:name].should eql("blue")
    group_static_models[0][:target_version].should eql("2.2")
    group_static_models[0][:target_participation].should eql(false)

    group_static_models[1][:name].should eql("green")
    group_static_models[1][:target_version].should eql("2.3")
    group_static_models[1][:target_participation].should eql(true)
  end

  it 'saves list of groups, with target_version and participation to a new yaml file' do
    cmdb =  Orc::CMDB::Yaml.new(:data_dir=>"spec/fixtures/cmdb/")
    group_static_models = cmdb.retrieve_application(:environment=>"cmdb_test", :application=>"testx")
    group_static_models[1][:target_version]="77"
    group_static_models[1][:target_participation]=false

    rand = (rand()*1000).ceil
    Dir.mkdir("build/")
    cmdb =  Orc::CMDB::Yaml.new(:data_dir=>"build/")
    cmdb.save_application({:environment=>"cmdb_test_#{rand}",:application=>"testx"}, group_static_models)
    group_static_models_again = cmdb.retrieve_application(:environment=>"cmdb_test_#{rand}", :application=>"testx")

    group_static_models_again[1][:target_version].should eql("77")
    group_static_models_again[1][:target_participation].should eql(false)
  end

  it 'saves list of groups, with target_version and participation to an existing yaml file' do
    rand = (rand()*1000).ceil

    yaml_content = {
      'testfred'=>[
      {
      :target_version=> "1",
      :name=> 'blue',
      :target_participation=> false},
      {
      :target_version=>  "2",
      :name =>"green",
      :target_participation=> false}
      ],
      'testbob'=>[
      {
      :target_version=> "3",
      :name=> 'blue',
      :target_participation=> false},
      {
      :target_version=>  "4",
      :name =>"green",
      :target_participation=> false}
      ]

    }
    group_static_models = [
      {
        :target_version=> "1",
        :name=>"blue",
        :target_participation=> false
      },
      {
        :target_version=> "77",
        :name=> "green",
        :target_participation=> false
      },
    ]

    testdir = "build/cmdb_test_#{rand}"
    if !Pathname.new(testdir).exist?
      Dir.mkdir testdir
    end
    File.open("#{testdir}/testfred.yaml", "w") do |f|
      f.write(yaml_content["testfred"].to_yaml)
    end
    File.open("#{testdir}/testbob.yaml", "w") do |f|
      f.write(yaml_content["testbob"].to_yaml)
    end

    cmdb =  Orc::CMDB::Yaml.new(:data_dir=>"build/")
    cmdb.save_application({:environment=>"cmdb_test_#{rand}",:application=>"testx"}, group_static_models)

    group_static_models_again = cmdb.retrieve_application(:environment=>"cmdb_test_#{rand}", :application=>"testx")
    group_static_models_again[1][:target_version].should eql("77")
    group_static_models_again[1][:target_participation].should eql(false)

    group_static_models_again = cmdb.retrieve_application(:environment=>"cmdb_test_#{rand}", :application=>"testbob")
    group_static_models_again[1][:target_version].should eql("4")
    group_static_models_again[1][:target_participation].should eql(false)
  end
end
