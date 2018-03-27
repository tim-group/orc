require 'orc/actions'
require 'orc/live_change_resolver'

class Orc::RestartResolver
  def initialize(remote_client, timeout = nil)
    change_required_check = Proc.new do |instance|
      !instance.restarted?
    end
    @resolver = Orc::LiveChangeResolver.new('RestartAction', change_required_check, remote_client, timeout)
  end

  def resolve(instance)
    @resolver.resolve(instance)
  end
end
