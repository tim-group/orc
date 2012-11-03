require 'mcollective'
require 'client/namespace'
require 'client/statuses'
require 'progress/progress_log'
require 'pp'

class MCollective::RPC::DeploytoolWrapper
  include MCollective::RPC

  def initialize(environment, options)
    @environment = environment
    @options = options
  end


  def status(spec)
    mc = rpcclient("deployapp",{:options => @options})
    mc.discover :verbose=>true
    mc.progress = false
    mc.verbose = true
    mc.status(:spec=>spec)
  end
end

class Client::DeployClient
  include ProgressLog
  include MCollective::RPC

  def initialize(args)
    @environment = args[:environment] or "default"
    @application = args[:application] or "default"
    @options =  MCollective::Util.default_options
    @options[:timeout] = 120

    if args[:config]!=nil
      @options[:config] = args[:config]
    end
    @options[:verbose] = true
    @mcollective_client = args[:mcollective_client] || DeploytoolWrapper.new(@environment, @options)
  end

  def status(spec={})
    spec[:environment] = @environment
    instances=[]

    @mcollective_client.status(spec).each do |resp|
      data  = resp[:data]
      if ! data.kind_of?(Array)
        next
      end

      data.each do |instance|
        instance[:host] = resp[:sender]
        instances<<instance
      end
    end

    return Statuses.new(instances)
  end

  def update_to_version(spec,hosts,version)
    @mc = rpcclient("deployapp",{:options => @options})
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    mc = @mc
    mc.progress = false
    mc.verbose = false

    mc.custom_request("update_to_version", {:spec=>spec, :version=>version}, hosts[0], {"identity"=>hosts[0]}).each do |resp|
      log_response(resp)
    end
  end

  def enable_participation(spec,hosts)
    @mc = rpcclient("deployapp",{:options => @options})
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    mc = @mc
    mc.progress = false
    mc.verbose = false

    mc.custom_request("enable_participation", {:spec=>spec}, hosts[0], {"identity"=>hosts[0]}).each do |resp|
      log_response(resp)
    end
  end

  def disable_participation(spec,hosts)
    @mc = rpcclient("deployapp",{:options => @options})
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    mc = @mc
    mc.progress = false
    mc.verbose = false
    mc.custom_request("disable_participation", {:spec=>spec}, hosts[0], {"identity"=>hosts[0]}).each do |resp|
      log_response(resp)
    end
  end

  def log_response(resp)
    data  = resp[:data]
    data[:logs][:infos].each do |log|
      log_client_response(resp[:sender], log)
    end
    data[:logs][:warns].each do |log|
      log_client_response(resp[:sender], log)
    end
    data[:logs][:errors].each do |log|
      log_client_response(resp[:sender], log)
    end
  end

end
