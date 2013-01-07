$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/util/option_parser'

describe Orc::Util::OptionParser do

  it 'can be constructed' do
    foo = Orc::Util::OptionParser.new
  end

  # FIXME - We need tests for each set of command options
  #         on the command line - how do you locally override @ARGV
  #         inside a test to be able to test this?
  it 'parses options from argv and passes them to option class constructor'
  it 'passes an Orc::Factory instance to the execute method'

  it 'parses other options and passes them to option class constructor'
end


