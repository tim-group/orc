require 'orc/namespace'
require 'yaml'

class Orc::Config
  def initialize(config_location)
    @config_location = config_location
    @tried_to_load_config = false
    @config = {
      'cmdb_repo_url' => 'git@git:cmdb',
      'cmdb_local_path' => '/opt/orctool/data/cmdb/',
    }
  end
  def load_config
    return if @tried_to_load_config
    @tried_to_load_config = true
    if File.exist?(@config_location)
      @config = YAML::load(File.open(@config_location))
    end
  end
  def [](key)
    load_config
    @config[key]
  end
end

