require 'orc/util/config'
require 'tmpdir'

class Orc::Util::Config
  attr_reader :config
end

describe Orc::Util::Config do
  it 'can construct and read defaults' do
    c = Orc::Util::Config.new('/tmp/does_not_exist.yaml')
    expect(c.config).to eql('cmdb_repo_url' => 'git@git.net.local:cmdb',
                            'cmdb_local_path' => "#{ENV['HOME']}/.cmdb/")
  end

  it 'can read a YAML file' do
    Dir.mktmpdir do |dir|
      data = {
        'cmdb_repo_url' => 'git@github.com:footest.git',
        'cmdb_local_path' => '/tmp/test-cmdb',
        'other' => 'stuff'
      }
      fn = "#{dir}/test.yaml"
      File.open(fn, 'w') do |f|
        f.write data.to_yaml
      end

      c = Orc::Util::Config.new(fn)
      expect(c['cmdb']).to eql(data['cmdb'])
      expect(c['other']).to eql('stuff')
    end
  end
end
