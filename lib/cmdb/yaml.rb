require 'cmdb/namespace'
require 'pathname'

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
      data = YAML::load(File.open(convention(spec)))
    else
      data = YAML::load(File.open("#{@data_dir}/#{spec[:environment]}.yaml"))["#{spec[:application]}"]
    end
    data.map { |el| Hash[el.map{|(k,v)| [k.to_sym,v]}] }
  end

  def save_application(spec, groups)
    file = convention(spec)
    dir = Pathname.new(file).dirname
    if !dir.exist?
        Dir.mkdir dir
    end
    flattened = groups.map { |el| Hash[el.map{|(k,v)| [k.to_s,v]}] }
    File.open( convention(spec), "w" ) do |f|
      f.write( flattened.to_yaml )
    end
  end
end

