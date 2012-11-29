require 'cmdb/namespace'

class CMDB::Yaml
  def initialize(args)
    @data_dir = args[:data_dir]
    if !Pathname.new(@data_dir).exist?
      Dir.mkdir @data_dir
    end
  end

  def convention(spec)
    return "#{@data_dir}#{spec[:environment]}/#{spec[:application]}.yaml"
  end

  def retrieve_application(spec)
    if Pathname.new(convention(spec)).exist?
      YAML::load(File.open(convention(spec)))
    else
      YAML::load(File.open("#{@data_dir}/#{spec[:environment]}.yaml"))["#{spec[:application]}"]
    end    
  end

  def save_application(spec, groups)
    file = convention(spec)
    dir = Pathname.new(file).dirname
    if !dir.exist?
        Dir.mkdir dir
    end
    File.open( convention(spec), "w" ) do |f|
      f.write( groups.to_yaml )
    end
  end
end

