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
      Subscribed
      TeamMention
    end
  end
end
