require 'progress/log'

module Orc
  class NoNonParticipatingGroupsToUpdateException < Exception
  end

  class IllegalAttemptToEnableParticipation < Exception
  end

  class FailedToResolve < Exception
  end

  class GroupMissing < Exception
  end

  class TimeoutError < Exception
  end

  module Util
  end
end

