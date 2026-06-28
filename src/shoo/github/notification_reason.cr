module Shoo
  module GitHub
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

      def description : String
        case self
        when .comment?      then "you commented"
        when .assign?       then "assigned to you"
        when .author?       then "you opened it"
        when .manual?       then "manually subscribed"
        when .mention?      then "you were mentioned"
        when .team_mention? then "your team was mentioned"
        when .ci_activity?  then "CI activity"
        else                     to_s.underscore.tr("_", " ")
        end
      end

      def colourise(width : Int32) : String
        padded = to_s.ljust(width)

        case self
        when .ci_activity?
          padded.colorize.yellow
        when .review_requested?
          padded.colorize.magenta
        when .mention?
          padded.colorize.green
        when .comment?
          padded.colorize.blue
        else
          padded.colorize.white
        end.to_s
      end
    end
  end
end
