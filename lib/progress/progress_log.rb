module ProgressLog
  def execute_step(description, &block)
    start_time = Time.now
    print "[\e[1;34mstarting\e[0m] #{description}\e[0m\n"
    begin
      block.call()
    rescue Exception=>e
      #      print "[\e[1;38mfailed\e[0m]\n"
    end
    end_time = Time.now
    print "[\e[1;32msuccess in #{(end_time-start_time)*1000}ms\e[0m]"
  end

  def log(description, &block)
    block.call()
    print  "  [\e[1;28mresolution\e[0m] #{description}\n"
  end

  def log_cmdb_change(description, &block)
    print  "  [\e[1;33mcmdb\e[0m]#{description}\n"
  end

  def log_client_response(host, log)
    print  "  [\e[1;50m#{host}\e[0m] #{log}\n"
  end

  def log_client_response_error(host, log)
    print  "  [\e[1;31m#{host}\e[0m] #{log}\n"
  end

  class ProgressLog::Logger
    include ProgressLog
  end

end
