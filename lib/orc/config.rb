require 'orc/namespace'
require 'yaml'

class Orc::Config
  def initialize
    @config_location = "#{ENV['HOME']}/.orc.yml"
    @tried_to_load_config = false
    @config = {
      'cmdb' => {
        'repo_url' => 'git@git:cmdb',
        'local_path' => '/opt/orctool/data/cmdb/',
      }
    }
  end
  def load_config
    @tried_to_load_config = true
    if File.exist?(@config_location)
      @config = YAML::LoadFile(@config_location)
    end
  end
  def [](key)
    @config[key]
  end
end

