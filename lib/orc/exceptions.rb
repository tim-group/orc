require 'orc/namespace'

module Orc::Exception
  class FailedToResolve < Exception
  end

  class FailedToDiscover < Exception
  end

  class GroupMissing < Exception
  end

  class Timeout < Exception
  end

  class CannotRestartUnresolvedGroup < Exception
  end
end
