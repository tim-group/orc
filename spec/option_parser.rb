$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'util/orc_option_parser'

describe Util::OrcOptionParser do

  it 'can be constructed' do
    foo = Util::OrcOptionParser.new
  end
end
