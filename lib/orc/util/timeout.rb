require 'orc/exceptions'
require 'dl/import'

module Orc::Util::Timeout
  module Alarm
    # This magic gives us an alarm(INT) method ala the libc function
    begin
      extend DL::Importable
    rescue # For ruby >= 1.9
      extend DL::Importer
    end
    if RUBY_PLATFORM =~ /darwin/
      so_ext = 'dylib'
    else
      so_ext = 'so.6'
    end
    dlload "libc.#{so_ext}"
    extern "unsigned int alarm(unsigned int)"
  end

  def timeout(interval)
    Signal.trap("ALRM") do
      raise Orc::Exception::Timeout.new("Timed out after #{interval}")
    end
    Alarm.alarm(interval)
    yield
    Alarm.alarm(0)
  end
end
