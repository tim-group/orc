require 'orc/util/namespace'
require 'yaml'

class Orc::Util::Config
  def initialize(config_location = "#{ENV['HOME']}/.orc.yaml")
    @config_location = config_location
    @tried_to_load_config = false
    @config = {
      'cmdb_repo_url' => 'git@git.net.local:cmdb',
      'cmdb_local_path' => "#{ENV['HOME']}/.cmdb/"
    }
  end

  def [](key)
    load_config
    @config[key]
  end

  private

  def load_config
    return if @tried_to_load_config
    @tried_to_load_config = true
    @config = YAML::load(File.open(@config_location)) if File.exist?(@config_location)
  end
end
