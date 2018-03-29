require 'orc/engine/namespace'
require 'orc/engine/actions'
require 'orc/engine/live_change_resolver'

class Orc::Engine::MismatchResolver
  def initialize(remote_client, timeout = nil)
    change_required_check = Proc.new do |instance|
      instance.version_mismatch?
    end
    @resolver = Orc::Engine::LiveChangeResolver.new(
      'UpdateVersionAction',
      change_required_check,
      remote_client,
      timeout
    )
  end

  def resolve(instance)
    @resolver.resolve(instance)
  end
end
