require 'orc/util/option_parser'

describe Orc::Util::OptionParser do
  it 'parses options from argv and passes them to option class constructor' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--environment', 'foo', '--application', 'bar', '-r'])

    expect(parser.options).to eql(:environment => 'foo', :application => 'bar')
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::ResolveRequest')
    expect(command.options).to eql(:environment => 'foo', :application => 'bar')
  end

  it 'Works with just --status and --environment' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--status', '--environment', 'bar'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::StatusRequest')
  end

  it 'Works for DeployRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::DeployRequest')
  end

  it 'Works for PromotionRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['-u', '--promote-from', 'baz', '--environment', 'bar', '--application', 'MyApp'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::PromotionRequest')
  end

  it 'Works for InstallRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for LimitedInstallRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--limited-install', '--environment', 'bar', '--application', 'MyApp', '--version', '1'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::LimitedInstallRequest')
  end

  it 'Works for InstallRequest with groups' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--install', '--environment', 'bar', '--application', 'MyApp', '--version', '1', '--group', 'blue'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.options[:group]).to eql 'blue'
    expect(command.class.name).to eql('Orc::Util::OptionParser::InstallRequest')
  end

  it 'Works for SwapRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--swap', '--environment', 'bar', '--application', 'MyApp'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::SwapRequest')
  end

  it 'Works for DeployRequest' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--deploy', '--environment', 'bar', '--application', 'MyApp', '--version', '1'])
    expect(parser.commands.size).to eql(1)
    command = parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::DeployRequest')
  end

  it 'will exit 1 when invalid option provided' do
    begin
      parser = Orc::Util::OptionParser.new
      parser.parse(['--socks', '--environment', 'bar', '--application', 'MyApp', '--group', 'blue'])
    rescue SystemExit => e
      expect(e.status).to eql(1)
    end
  end

  it 'accepts max_wait parameter as integer number of seconds' do
    parser = Orc::Util::OptionParser.new
    parser.parse(['--environment', 'foo', '--application', 'bar', '-r', '--max-wait', '42'])

    expect(parser.options[:max_wait]).to eql(42)
  end
end
