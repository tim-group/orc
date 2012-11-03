require 'cmdb/namespace'

class CMDB::Yaml
  def initialize(args)
    @data_dir = args[:data_dir]
  end

  def convention(spec)
    return "#{@data_dir}/#{spec[:environment]}.yaml"
  end

  def retrieve_application(spec)
    from_yaml = YAML::load(File.open(convention(spec)))
    groups = from_yaml["#{spec[:application]}"]
    return groups
  end

  def save_application(spec, groups)
    file =convention(spec)
    if (File.exist?(file))
      to_save = YAML::load(File.open(file))
    else
      to_save = {}
    end
    to_save["#{spec[:application]}"] = groups
    File.open( convention(spec), "w" ) do |f|
      f.write( to_save.to_yaml )
    end
  end
end