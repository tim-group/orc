require 'orc/cmdb/namespace'
require 'pathname'
require 'yaml'

class Orc::CMDB::Yaml
  def initialize(args)
    @data_dir = args[:data_dir]
  end

  def convention(spec)
    return "#{@data_dir}#{spec[:environment]}/#{spec[:application]}.yaml"
  end

  def retrieve_application(spec)
    YAML::load(File.open(convention(spec))).map { |el| Hash[el.map{|(k,v)| [k.to_sym,v]}] }
  end

  def save_application(spec, groups)
    filename = convention(spec)
    dir = Pathname.new(filename).dirname
    if !dir.exist?
        Dir.mkdir dir
    end
    File.open(filename, "w") do |f|
      flattened = groups.map { |el| Hash[el.map{|(k,v)| [k.to_s,v]}] }
      f.write(flattened.to_yaml)
    end
  end
end
