$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'orc/util/option_parser'

describe Orc::Util::OptionParser do

  it 'can be constructed' do
    foo = Orc::Util::OptionParser.new
  end
end
