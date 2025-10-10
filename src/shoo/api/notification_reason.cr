module Shoo
  module API
    enum NotificationReason
      ApprovalRequested
      Assign
      Author
      CiActivity
      Comment
      Invitation
      Manual
      MemberFeatureRequested
      Mention
      ReviewRequested
      SecurityAdvisoryCredit
      SecurityAlert
      StateChange
      Subscribed
      TeamMention
    end
  end
end
