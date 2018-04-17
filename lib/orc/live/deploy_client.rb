require 'mcollective'
require 'orc/live/namespace'
require 'orc/util/progress_reporter'

class MCollective::RPC::DeploytoolWrapper
  include MCollective::RPC

  def initialize(environment)
    @environment = environment
  end

  def status(spec, maybe_offline_hosts = [])
    spec[:environment] = @environment if spec[:environment].nil?
    online_hosts = discover_hosts(spec[:environment], spec[:application], spec[:group])
    status_of(spec, online_hosts - maybe_offline_hosts, 200) + status_of(spec, maybe_offline_hosts, 10)
  end

  def custom_request(action, request, hosts, timeout = 200)
    get_client(timeout).custom_request(action, request, hosts, 'agent' => 'deployapp')
  end

  private

  def discover_hosts(environment = nil, application = nil, group = nil)
    # FIXME: Occasionally this dies with Marshal errors, just retry once..
    attempt_discovery(environment, application, group)
  rescue
    attempt_discovery(environment, application, group)
  end

  def status_of(spec, hosts, timeout)
    hosts.empty? ? [] : custom_request("status", { :spec => spec }, hosts, timeout)
  end

  def attempt_discovery(environment = nil, application = nil, group = nil)
    mc = rpcclient("deployapp", :options => MCollective::Util.default_options)
    mc.fact_filter "logicalenv", environment unless environment.nil?
    mc.fact_filter "application", application unless application.nil?
    mc.fact_filter "group", group unless group.nil?
    mc.discover(:verbose => false).sort
  end

  def get_client(timeout)
    mco_options = MCollective::Util.default_options
    mco_options[:timeout] = timeout if timeout
    mco_options[:verbose] = true
    mc = rpcclient("deployapp", :options => mco_options)
    mc.progress = false
    mc.verbose = true
    mc
  end
end

class Orc::DeployClient
  def initialize(args)
    @logger = args[:log] || ::Orc::Util::ProgressReporter::Logger.new
    @environment = args[:environment]
    @application = args[:application]
    @group = args[:group]
    @debug = args[:debug]
    @mco_client = args[:mcollective_client] || MCollective::RPC::DeploytoolWrapper.new(@environment)
  end

  def status(spec = {}, maybe_offline_hosts = [])
    instances = []

    spec[:application] = @application if !@application.nil?
    spec[:group] = @group if !@group.nil?

    @mco_client.status(spec, maybe_offline_hosts).each do |resp|
      data = resp[:data]

      if data.is_a?(Hash) && data.has_key?(:statuses)
        raw_instances = data[:statuses]
      else
        raw_instances = data
      end

      next if !raw_instances.is_a?(Array)

      raw_instances.each do |instance|
        instance[:host] = resp[:sender]
        instances << instance
      end
    end

    if instances.empty? && maybe_offline_hosts.empty?
      error = "Did not find any instances of #{@application} in #{@environment}"
      error = "Did not find any instances of #{@application} #{@group} in #{@environment}" unless @group.nil?
      raise Orc::Live::FailedToDiscover.new(error)
    end

    instances
  end

  def update_to_version(spec, hosts, version)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?

    @mco_client.custom_request("update_to_version", { :spec => spec, :version => version }, hosts).each do |resp|
      log_response(resp)
      return resp[:data][:successful]
    end

    false
  end

  def enable_participation(spec, hosts)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    @mco_client.custom_request("enable_participation", { :spec => spec }, hosts).each do |resp|
      log_response(resp)
    end
  end

  def disable_participation(spec, hosts)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?

    @mco_client.custom_request("disable_participation", { :spec => spec }, hosts).each do |resp|
      log_response(resp)
    end
  end

  def restart(spec, hosts)
    spec[:environment] = @environment
    spec[:application] = @application if spec[:application].nil?
    @mco_client.custom_request("restart", { :spec => spec }, hosts).each do |resp|
      log_response(resp)
      return resp[:data][:successful]
    end

    false
  end

  def clean_instance(host)
    stacks(host, 'clean')
  end

  def provision_instance(host)
    stacks(host, 'provision')
  end

  def reprovision_instance(host)
    stacks(host, 'reprovision')
  end

  private

  def stacks(stack, command)
    verbosity = @debug ? '-vv' : ''
    system("stacks #{verbosity} --checkout-config --environment '#{@environment}' --stack '#{stack}' #{command}")
  end

  def log_response(resp)
    data  = resp[:data]
    data[:logs][:infos].each { |log| @logger.log_client_response(resp[:sender], log) }
    data[:logs][:warns].each { |log| @logger.log_client_response(resp[:sender], log) }
    data[:logs][:errors].each { |log| @logger.log_client_response_error(resp[:sender], log) }
  end
end
