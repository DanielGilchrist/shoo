module Shoo
  module API
    enum NotificationReason
      Assign
      Author
      CiActivity
      Comment
      Mention
      ReviewRequested
      SecurityAlert
      StateChange
      TeamMention
    end
  end
end
