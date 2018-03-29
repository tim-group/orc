require 'orc/util/namespace'

module Orc::Util::ProgressReporter
  def self.logger
    Orc::Util::ProgressReporter::Logger.new
  end

  def logger
    Orc::Util::ProgressReporter::Logger.new
  end

  def self.null_logger
    Orc::Util::ProgressReporter::NullLogger.new
  end

  class Logger
    def log(msg)
      print "[\e[1;27m#{msg}\e[0m]\n"
    end

    def log_action(msg)
      print "[\e[0;33m#{msg}\e[0m]\n"
    end

    def log_resolution_complete(resolutions)
      print "[\e[1;32msuccess - resolution complete\e[0m]\n"
      resolutions.each do |r|
        print "    #{r}\n"
      end
    end

    def log_client_response(host, log)
      log = log.map { |k, v| "#{k}=#{v}" }.join('; ') if log.is_a? Hash
      print "  [\e[1;50m#{host}\e[0m] #{log}\n"
    end

    def log_client_response_error(host, log)
      log = log.map { |k, v| "#{k}=#{v}" }.join('; ') if log.is_a? Hash
      print "  [\e[1;31m#{host}\e[0m] #{log}\n"
    end
  end

  class NullLogger
    def log(_msg)
    end

    def log_action(_msg)
    end

    def log_resolution_complete(_resolutions)
    end

    def log_client_response(_host, _log)
    end

    def log_client_response_error(_host, _log)
    end
  end
end
