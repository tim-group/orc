require 'mcollective'
require 'orc/namespace'
require 'orc/progress'
require 'pp'
require 'orc/exceptions'

class MCollective::RPC::DeploytoolWrapper
  include MCollective::RPC

  def initialize(environment, options)
    @environment = environment
    @options = options
  end

  def status(spec)
    spec[:environment] = @environment if spec[:environment].nil?
    get_client(spec[:environment], spec[:application], spec[:group]).status(:spec => spec)
  end

  def custom_request(action, request, hosts, identity_hash)
    get_client.custom_request(action, request, hosts, identity_hash)
  end

  private

  def get_client(environment = nil, application = nil, group = nil)
    begin # FIXME - Occasionally this dies with Marshal errors, just retry once..
      mc = rpcclient("deployapp", { :options => @options })
      unless environment.nil?
        mc.fact_filter "logicalenv", environment
      end
      unless application.nil?
        mc.fact_filter "application", application
      end
      unless group.nil?
        mc.fact_filter "group", group
      end
      mc.discover :verbose => false
    rescue
      mc = rpcclient("deployapp", { :options => @options })
      unless environment.nil?
        mc.fact_filter "logicalenv", environment
      end
      unless application.nil?
        mc.fact_filter "application", application
      end
      unless group.nil?
        mc.fact_filter "group", group
      end
      mc.discover :verbose => false
    end
    mc.progress = false
    mc.verbose  = true
    mc
  end
end

class Orc::DeployClient
  include MCollective::RPC

  def initialize(args)
    @logger = args[:log] || ::Orc::Progress::Logger.new()
    @options =  MCollective::Util.default_options
    @options[:timeout] = 200

    @environment = args[:environment]
    @application = args[:application]
    @group = args[:group]
    if args[:config] != nil
      @options[:config] = args[:config]
    end

    @options[:verbose] = true
    @mcollective_client = args[:mcollective_client] || DeploytoolWrapper.new(@environment, @options)
  end

  def status(spec = {})
    instances = []

    spec[:application] = @application if !@application.nil?
    spec[:group] = @group if !@group.nil?

    @mcollective_client.status(spec).each do |resp|
      data  = resp[:data]

      if data.kind_of?(Hash) and data.has_key?(:statuses)
        raw_instances = data[:statuses]
      else
        raw_instances = data
      end

      if !raw_instances.kind_of?(Array)
        next
      end

      raw_instances.each do |instance|
        instance[:host] = resp[:sender]
        instances << instance
      end
    end

    if 0 == instances.count
      error = "Did not find any instances of #{@application} in #{@environment}"
      error = "Did not find any instances of #{@application} #{@group} in #{@environment}" unless @group.nil?
      raise Orc::Exception::FailedToDiscover.new(error)
    end

    instances
  end

  def update_to_version(spec, hosts, version)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?

    @mcollective_client.custom_request("update_to_version", { :spec => spec, :version => version }, hosts[0], { "identity" => hosts[0] }).each do |resp|
      log_response(resp)
      return resp[:data][:successful]
    end

    false
  end

  def enable_participation(spec, hosts)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    @mcollective_client.custom_request("enable_participation", { :spec => spec }, hosts[0], { "identity" => hosts[0] }).each do |resp|
      log_response(resp)
    end
  end

  def disable_participation(spec, hosts)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?

    @mcollective_client.custom_request("disable_participation", { :spec => spec }, hosts[0], { "identity" => hosts[0] }).each do |resp|
      log_response(resp)
    end
  end

  def log_response(resp)
    data  = resp[:data]
    data[:logs][:infos].each do |log|
      @logger.log_client_response(resp[:sender], log)
    end
    data[:logs][:warns].each do |log|
      @logger.log_client_response(resp[:sender], log)
    end
    data[:logs][:errors].each do |log|
      @logger.log_client_response_error(resp[:sender], log)
    end
  end
end
