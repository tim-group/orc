require 'orc/factory'

describe Orc::MismatchResolver do
  before do
    @mismatch_resolver = Orc::MismatchResolver.new(nil)
    @should_be_participating_group = Orc::Model::Group.new(
      :name                 => "spg",
      :target_participation => true,
      :target_version       => "correct"
    )
    @should_not_be_participating_group = Orc::Model::Group.new(
      :name                 => "snpg",
      :target_participation => false,
      :target_version       => "correct"
    )
  end

  it 'sends update when should not be participating, is not participating and has a version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect_version",
        :health        => "healthy",
        :stoppable     => "safe"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends wait when should not be participating, is not participating and has a version mismatch but not stoppable' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect_version",
        :health        => "healthy",
        :stoppable     => "unwise"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::WaitForDrainedAction)
  end

  it 'sends disable when should be participating, is participating and has a version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => true,
        :version       => "incorrect_version",
        :health        => "healthy"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends update when is not participating and there is a version mismatch only' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect_version",
        :health        => "healthy",
        :stoppable     => "safe"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends wait when is not participating and there is a version mismatch only but not stoppable' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect_version",
        :health        => "healthy",
        :stoppable     => "unwise"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::WaitForDrainedAction)
  end

  it 'sends disable when is participating and there is a version mismatch only' do
    instance = Orc::Model::Instance.new(
      {
        :participating => true,
        :version       => "incorrect_version",
        :health        => "healthy",
        :stoppable     => "safe"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends enable when should be participating but is not and there is no version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "correct",
        :health        => "healthy"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::EnableParticipationAction)
  end

  it 'sends disable when should not be participating but is and there is no version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => true,
        :version       => "correct",
        :health        => "healthy"
      },
      @should_not_be_participating_group)

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::DisableParticipationAction)
  end

  it 'sends update when should be participating, is not participating and has a version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect",
        :health        => "healthy",
        :stoppable     => "safe"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends update when should be participating, is not participating and has a version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect",
        :health        => "healthy",
        :stoppable     => "safe"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::UpdateVersionAction)
  end

  it 'sends wait when should be participating, is not participating and has a version mismatch' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "incorrect",
        :health        => "healthy",
        :stoppable     => "unwise"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::WaitForDrainedAction)
  end

  it 'is waiting for healthy when is unhealthy but should be participating, is not yet participating and has correct ' \
     'version' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "correct",
        :health        => "ill"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::WaitForHealthyAction)
  end

  it 'also waits for healthy when a participating instance is ill' do
    instance = Orc::Model::Instance.new(
      {
        :participating => true,
        :version       => "correct",
        :health        => "ill"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::WaitForHealthyAction)
  end

  it 'is resolved when should be participating, is participating and has correct version' do
    instance = Orc::Model::Instance.new(
      {
        :participating => true,
        :version       => "correct",
        :health        => "healthy"
      },
      @should_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::ResolvedCompleteAction)
  end

  it 'is resolved when should not be participating, is not participating and has correct version' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "correct",
        :health        => "healthy"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::ResolvedCompleteAction)
  end

  it 'is resolved when should not be participating, is not participating and has correct version even if unhealthy' do
    instance = Orc::Model::Instance.new(
      {
        :participating => false,
        :version       => "correct",
        :health        => "ill"
      },
      @should_not_be_participating_group
    )

    resolution = @mismatch_resolver.resolve(instance)
    expect(resolution.class).to eql(Orc::Action::ResolvedCompleteAction)
  end

  it 'will not send a disable when there would be no groups left in the lb pool' do
    instances = [
      Orc::Model::Instance.new(
        {
          :participating => true,
          :version       => "correct",
          :health        => "healthy"
        },
        @should_not_be_participating_group
      ),
      Orc::Model::Instance.new(
        {
          :participating => false,
          :version       => "correct",
          :health        => "healthy"
        },
        @should_not_be_participating_group
      )
    ]

    resolution = @mismatch_resolver.resolve(instances[0])
    expect(resolution.class).to eql(Orc::Action::DisableParticipationAction)

    mock_appmodel = double
    allow(mock_appmodel).to receive(:instances).and_return(instances)
    allow(mock_appmodel).to receive(:participating_instances).and_return([instances[0]])

    expect { resolution.check_valid(mock_appmodel) }.to raise_error(Orc::Exception::FailedToResolve)
  end
end
