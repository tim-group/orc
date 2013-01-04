require 'orc/namespace'

module Orc::Exception
  class FailedToResolve < Exception
  end

  class GroupMissing < Exception
  end

  class Timeout < Exception
  end
end

