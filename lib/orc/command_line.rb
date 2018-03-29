require 'orc/namespace'
require 'orc/util/option_parser'
require 'orc/factory'

user = ENV['USER']
ENV['MCOLLECTIVE_SSL_PRIVATE'] = "/home/#{user}/.mc/#{user}-private.pem" unless ENV.has_key?('MCOLLECTIVE_SSL_PRIVATE')
ENV['MCOLLECTIVE_SSL_PUBLIC'] = "/etc/mcollective/ssl/clients/#{user}.pem" unless ENV.has_key?('MCOLLECTIVE_SSL_PUBLIC')

class Orc::CommandLine
  def initialize
    @option_parser = Orc::Util::OptionParser.new
  end

  def execute(args)
    @option_parser.parse(args)
    @option_parser.commands.each do |command|
      command.execute(Orc::Factory.new(@option_parser.options))
    end
  end
end
