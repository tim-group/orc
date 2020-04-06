require 'orc/engine/namespace'
require 'orc/engine/actions'
require 'orc/engine/live_change_resolver'

class Orc::Engine::MismatchResolver
  def initialize(remote_client, max_wait, timeout = nil, reprovision = false)
    change_required_check = Proc.new do |instance|
      instance.version_mismatch?
    end
    @resolver = Orc::Engine::LiveChangeResolver.new(
      reprovision ? 'CleanInstanceAction' : 'UpdateVersionAction',
      change_required_check,
      remote_client,
      max_wait,
      timeout
    )
  end

  def resolve(instance)
    @resolver.resolve(instance)
  end
end
