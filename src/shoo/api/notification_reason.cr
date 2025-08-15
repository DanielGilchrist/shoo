module Shoo
  module API
    enum NotificationReason
      Assign
      Author
      CiActivity
      Comment
      Manual
      Mention
      ReviewRequested
      SecurityAlert
      StateChange
      TeamMention
    end
  end
end
