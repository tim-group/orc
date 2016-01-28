require 'orc/util/option_parser'

class MockOptionParser < Orc::Util::OptionParser
  attr_reader :argv
  def initialize(argv)
    @argv = argv
    super()
  end
end

class Orc::Util::OptionParser
  attr_accessor :options, :commands, :option_parser
end

class Orc::Util::OptionParser::TestOption < Orc::Util::OptionParser::Base
  attr_accessor :have_run, :factory
  def required
    [:environment, :application, :version]
  end

  def execute(factory)
    @have_run = true
    @factory = factory
  end

  def self.command_options
    ['-z', '--zzzz', 'ZZZ']
  end
end

describe Orc::Util::OptionParser do
  it 'can be constructed' do
    Orc::Util::OptionParser.new
  end

  it 'Can parse and execute fake option' do
    p = MockOptionParser.new(['-z', '--environment', 'foo', '--application', 'bar', '--version', '2.5'])
    Orc::Util::OptionParser::TestOption.setup_command_options(p.options, p.option_parser, p.commands)
    p.parse
    expect($options).to eql(:environment => 'foo', :application => 'bar', :version => '2.5')
    expect(p.commands.size).to eql(1)
    command = p.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::TestOption')
    expect(command.have_run).to eql(nil)
    p.execute
    expect(command.have_run).to eql(true)
    expect(command.factory.class.name).to eql('Orc::Factory')
  end

  # FIXME: We need tests for each set of command options
  #        on the command line - how do you locally override @ARGV
  #        inside a test to be able to test this?
  it 'parses options from argv and passes them to option class constructor' do
    parser = MockOptionParser.new(['--environment', 'foo', '--application', 'bar', '-r']).parse

    expect($options).to eql(:environment => 'foo', :application => 'bar')
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::ResolveRequest')
    expect(command.options).to eql(:environment => 'foo', :application => 'bar')
  end

  it 'Works with just --show-status and --environment' do
    parser = MockOptionParser.new(['--show-status', '--environment', 'bar']).parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::StatusRequest')
  end

  it 'Works for DeployRequest' do
    parser = MockOptionParser.new(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::DeployRequest')
  end

  it 'Works for PromotionRequest' do
    parser = MockOptionParser.new(['-u', '--promote-from', 'baz', '--environment', 'bar', '--application', 'MyApp']).
             parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::PromotionRequest')
  end

  it 'Works for InstallRequest' do
    parser = MockOptionParser.new(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for LimitedInstallRequest' do
    parser = MockOptionParser.new(['--limited-install', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::LimitedInstallRequest')
  end

  it 'Works for InstallRequest with groups' do
    parser = MockOptionParser.new(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1',
                                   '--group', 'blue']).parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.options[:group]).to eql 'blue'
    expect(command.class.name).to eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for SwapRequest' do
    parser = MockOptionParser.new(['--swap', '--environment', 'bar', '--application', 'MyApp']).parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::SwapRequest')
  end

  it 'Works for DeployRequest' do
    parser = MockOptionParser.new(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::DeployRequest')
  end

  it 'Works for RollingRestartRequest' do
    parser = MockOptionParser.new(['--rolling-restart', '--environment', 'bar', '--application', 'MyApp',
                                   '--group', 'blue']).parse

    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::RollingRestartRequest')
  end
end
