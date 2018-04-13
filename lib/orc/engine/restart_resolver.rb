require 'orc/engine/namespace'
require 'orc/engine/actions'
require 'orc/engine/live_change_resolver'

class Orc::Engine::RestartResolver
  def initialize(remote_client, timeout = nil, reprovision = false)
    change_required_check = Proc.new do |instance|
      !instance.restarted?
    end
    @resolver = Orc::Engine::LiveChangeResolver.new(
      reprovision ? 'CleanInstanceAction' : 'RestartAction',
      change_required_check,
      remote_client,
      timeout
    )
  end

  def resolve(instance)
    @resolver.resolve(instance)
  end
end
