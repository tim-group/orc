require 'orc/model/builder'
require 'orc/testutil/in_memory_cmdb'
require 'orc/testutil/fake_remote_client'
require 'orc/util/progress_reporter'

describe Orc::Model::Builder do
  builder = Orc::Model::Builder.new(
    :environment => "a",
    :application => "app",
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
      }),
    :mismatch_resolver => {},
    :progress_logger => Orc::Util::ProgressReporter::NullLogger.new)

  builder_with_missing_instance = Orc::Model::Builder.new(
    :environment => "a",
    :application => "app",
    :remote_client => FakeRemoteClient.new(:instances => [
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
      }),
    :mismatch_resolver => {},
    :progress_logger => Orc::Util::ProgressReporter::NullLogger.new)

  it 'supports a vanilla pass through' do
    session = {}

    model = builder.create_live_model(session)[0]
    expect(model.instances.length).to eq 2
    instance = model.instances.detect { |i| i.host == "h1" }
    expect(instance.missing?).to be false
    expect(instance.being_cleaned?).to be false
    expect(instance.being_provisioned?).to be false

    instance.set_being_cleaned

    model = builder.create_live_model(session)[0]
    expect(model.instances.size).to eq 2
    instance = model.instances.detect { |i| i.host == "h1" }
    expect(instance.missing?).to be false
    expect(instance.being_cleaned?).to be true
    expect(instance.being_provisioned?).to be false

    model = builder_with_missing_instance.create_live_model(session)[0]
    expect(model.instances.size).to eq 2
    instance = model.instances.detect { |i| i.host == "h1" }
    expect(instance.missing?).to be true
    expect(instance.being_cleaned?).to be true
    expect(instance.being_provisioned?).to be false

    instance.set_being_provisioned

    model = builder_with_missing_instance.create_live_model(session)[0]
    expect(model.instances.size).to eq 2
    instance = model.instances.detect { |i| i.host == "h1" }
    expect(instance.missing?).to be true
    expect(instance.being_cleaned?).to be false
    expect(instance.being_provisioned?).to be true

    model = builder.create_live_model(session)[0]
    expect(model.instances.size).to eq 2
    instance = model.instances.detect { |i| i.host == "h1" }
    expect(instance.missing?).to be false
    expect(instance.being_cleaned?).to be false
    expect(instance.being_provisioned?).to be false
  end

  it 'refuses to clean a missing instance' do
    session = {}

    model = builder.create_live_model(session)[0]
    instance = model.instances.detect { |i| i.host == "h1" }
    instance.set_being_cleaned

    model = builder_with_missing_instance.create_live_model(session)[0]
    instance = model.instances.detect { |i| i.host == "h1" }
    expect { instance.set_being_cleaned }.to raise_error(RuntimeError)
  end

  it 'refuses to provision a present instance' do
    session = {}

    model = builder.create_live_model(session)[0]
    instance = model.instances.detect { |i| i.host == "h1" }
    expect { instance.set_being_provisioned }.to raise_error(RuntimeError)
  end
end
