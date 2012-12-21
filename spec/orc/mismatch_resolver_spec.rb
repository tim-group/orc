$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/actions'
require 'orc/mismatch_resolver'
require 'model/group_model'
require 'model/instance_model'

describe Orc::MismatchResolver do

  before do
    @mismatch_resolver = Orc::MismatchResolver.new(nil)
    @should_be_participating_group = Model::GroupModel.new(
    :name=>"spg",
    :target_participation=>true,
    :target_version=>"correct")
    @should_not_be_participating_group = Model::GroupModel.new(
    :name=>"snpg",
    :target_participation=>false,
    :target_version=>"correct")
  end

  it 'sends update when should not be participating, is not participating and has a version mismatch' do
    instance = Model::InstanceModel.new(
    {
      :participating=>false,
      :version=>"incorrect_version"
    },
    @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends disable when should be participating, is participating and has a version mismatch' do
    instance = Model::InstanceModel.new(
    {
      :participating=>true,
      :version=>"incorrect_version"
    },
    @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends update when is not participating and there is a version mismatch only' do
    instance = Model::InstanceModel.new(
    {
      :participating=>false,
      :version=>"incorrect_version"
    },
    @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends disable when is participating and there is a version mismatch only' do
    instance = Model::InstanceModel.new(
    {
      :participating=>true,
      :version=>"incorrect_version"
    },
    @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends enable when should be participating but is not and there is no version mismatch' do
    instance = Model::InstanceModel.new(
    {
      :participating=>false,
      :version=>"correct"
    },
    @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::EnableParticipationAction)
  end

  it 'sends disable when should not be participating but is and there is no version mismatch' do
    instance = Model::InstanceModel.new(
    {
      :participating=>true,
      :version=>"correct"
    },    @should_not_be_participating_group)

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends update when should be participating, is not participating and has a version mismatch' do
    instance = Model::InstanceModel.new(
    {
      :participating=>false,
      :version=>"incorrect"
    },
    @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::UpdateVersionAction)
  end

  it 'is resolved when should be participating, is participating and has correct version' do
    instance = Model::InstanceModel.new(
    {
      :participating=>true,
      :version=>"correct"
    },
    @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::ResolvedCompleteAction)
  end

  it 'is resolved when should not be participating, is not participating and has correct version' do
    instance = Model::InstanceModel.new(
    {
      :participating=>false,
      :version=>"correct"
    },
    @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    resolution.class.should eql(Orc::Action::ResolvedCompleteAction)
  end

  it 'will not send a disable when there would be no groups left in the lb pool' do

    instances =
    [Model::InstanceModel.new(
      {
      :participating=>true,
      :version=>"correct"
      },    @should_not_be_participating_group),
      Model::InstanceModel.new(
      {
      :participating=>false,
      :version=>"correct"
      },    @should_not_be_participating_group)]

    resolution = @mismatch_resolver.resolve(instances[0])
    resolution.class.should eql(Orc::Action::DisableParticipationAction)

    expect {resolution.check_valid(Model::ApplicationModel.new(instances))}.should raise_error(Orc::FailedToResolve)
  end

  it 'after evaluating all groups transitions, all enablements should take precedence over disablements'
end
