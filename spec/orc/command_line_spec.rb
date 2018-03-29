require 'orc/command_line'
require 'orc/util/option_parser'

class Orc::CommandLine
  attr_accessor :option_parser
end

class Orc::Util::OptionParser
  attr_accessor :option_parser
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

describe Orc::CommandLine do

  it 'Can parse and execute fake command' do
    commandline = Orc::CommandLine.new

    Orc::Util::OptionParser::TestOption.setup_command_options(
      commandline.option_parser.options,
      commandline.option_parser.option_parser,
      commandline.option_parser.commands
    )

    commandline.execute(['-z', '--environment', 'foo', '--application', 'bar', '--version', '2.5'])

    command = commandline.option_parser.commands[0]
    expect(command.class.name).to eql('Orc::Util::OptionParser::TestOption')
    expect(command.have_run).to eql(true)
    expect(command.options).to eql(:environment => 'foo', :application => 'bar', :version => '2.5')
    expect(command.factory.class.name).to eql('Orc::Factory')
  end

end
