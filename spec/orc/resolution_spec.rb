$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'spec_helper'
require 'rubygems'
require 'rspec'
require 'orc/factory'

describe Orc::Engine do
  class InMemoryCmdb
    def initialize(opts)
      @groups = opts[:groups]
    end

    def retrieve_application(spec)
      @groups["#{spec[:environment]}-#{spec[:application]}"]
    end
  end

  def fake_cmdb(opts)
    InMemoryCmdb.new(opts)
  end

  class FakeRemoteClient
    def initialize(opts)
      @instances = opts[:instances]
      @instances = [
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
          :health        => "healthy" }
      ] if @instances.nil?

      @fail_to_deploy = opts[:fail_to_deploy]
    end

    def update_to_version(spec, hosts, target_version)
      return @instances if @fail_to_deploy

      @instances = @instances.map do |instance|
        if (instance[:host] == hosts[0])
          instance[:version] = target_version
          instance
        else
          instance
        end
      end
    end

    def disable_participation(spec, hosts)
      @instances = @instances.map do |instance|
        if (instance[:host] == hosts[0])
          instance[:participating] = false
          instance
        else
          instance
        end
      end
    end

    def enable_participation(spec, hosts)
      @instances = @instances.map do |instance|
        if (instance[:host] == hosts[0])
          instance[:participating] = true
          instance
        else
          instance
        end
      end
    end

    def status(spec)
      @instances
    end
  end

  def remote_client(opts = {})
    FakeRemoteClient.new(opts)
  end

  it 'vanilla pass through' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()
    silence_output
    steps = engine.resolve()
    restore_output

    steps.should eq ["DisableParticipationAction: on h1 blue",
                     "UpdateVersionAction: on h1 blue",
                     "EnableParticipationAction: on h1 blue",
                     "DisableParticipationAction: on h2 blue",
                     "UpdateVersionAction: on h2 blue",
                     "EnableParticipationAction: on h2 blue"]
  end

  it 'safely deploys across multiple clusters' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()

    expect {
      silence_output
      steps = engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::FailedToResolve)
  end

  xit 'safely deploys across multiple clusters and app types' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()

    expect {
      silence_output
      steps = engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'safely deploys across multiple clusters and app types' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()

    expect {
      silence_output
      steps = engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'gives sensible error messages when cmdb info is missing' do
    factory = Orc::Factory.new({ :environment => "a", :application => "non-existent-app" }, {
     :remote_client => remote_client(:instances => [
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
     :cmdb => fake_cmdb(:groups => {}) })

    engine = factory.engine()

    expect {
      silence_output
      engine.resolve()
      restore_output
    }.to raise_error(Orc::CMDB::ApplicationMissing)
  end

  it 'raises an error when there is no cmdb information for the given group' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app" }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
        "a-app" => []
    }) })

    engine = factory.engine()

    expect {
      silence_output
      engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::GroupMissing)
  end

  it 'does nothing if all groups say they are resolved' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
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
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()
    silence_output
    steps = engine.resolve()
    restore_output

    steps.should eq []
  end

  it 'will fail - if there is one instance and the next action is to remove it' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:instances => [
        { :group => "blue",
          :host => "h1",
          :version => "2.2",
          :application => "app",
          :participating => true,
          :health        => "healthy" }]),
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => true,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()

    expect {
      silence_output
      engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::FailedToResolve)
  end

  it 'aborts if the same action is attempted twice - ie fails to deploy' do
    factory = Orc::Factory.new({ :environment => "a", :application => "app", :timeout => 0 }, {
      :remote_client => remote_client(:fail_to_deploy => true, :instances => [
        { :group => "blue",
          :host => "h1",
          :version => "2.2",
          :application => "app",
          :participating => false,
          :health        => "healthy" }]),
      :cmdb => fake_cmdb(:groups => {
            "a-app" => [{
              :name => "blue",
              :target_participation => false,
              :target_version => "5"
            }]
      })
    })
    engine = factory.engine()

    expect {
      silence_output
      engine.resolve()
      restore_output
    }.to raise_error(Orc::Exception::FailedToResolve)
  end
end
