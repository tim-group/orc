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
    p.options.should eql(:environment => 'foo', :application => 'bar', :version => '2.5')
    p.commands.size.should eql(1)
    command = p.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::TestOption')
    command.have_run.should eql(nil)
    p.execute
    command.have_run.should eql(true)
    command.factory.class.name.should eql('Orc::Factory')
  end

  # FIXME: We need tests for each set of command options
  #        on the command line - how do you locally override @ARGV
  #        inside a test to be able to test this?
  it 'parses options from argv and passes them to option class constructor' do
    parser = MockOptionParser.new(['--environment', 'foo', '--application', 'bar', '-r']).parse

    parser.options.should eql(:environment => 'foo', :application => 'bar')
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::ResolveRequest')
    command.options.should eql(:environment => 'foo', :application => 'bar')
  end

  it 'Works with just --pull-cmdb' do
    parser = MockOptionParser.new(['--pull-cmdb']).parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::PullCmdbRequest')
  end

  it 'Works with just --show-status and --environment' do
    parser = MockOptionParser.new(['--show-status', '--environment', 'bar']).parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::StatusRequest')
  end

  it 'Works for DeployRequest' do
    parser = MockOptionParser.new(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::DeployRequest')
  end

  it 'Works for PromotionRequest' do
    parser = MockOptionParser.new(['-u', '--promote-from', 'baz', '--environment', 'bar', '--application', 'MyApp']).
             parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::PromotionRequest')
  end

  it 'Works for InstallRequest' do
    parser = MockOptionParser.new(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for InstallRequest with groups' do
    parser = MockOptionParser.new(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1',
                                   '--group', 'blue']).parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.options[:group].should eql 'blue'
    command.class.name.should eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for SwapRequest' do
    parser = MockOptionParser.new(['--swap', '--environment', 'bar', '--application', 'MyApp']).parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::SwapRequest')
  end

  it 'Works for DeployRequest' do
    parser = MockOptionParser.new(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1']).
             parse
    parser.commands.size.should eql(1)
    command = parser.commands[0]
    command.class.name.should eql('Orc::Util::OptionParser::DeployRequest')
  end
end
