module Shoo
  module Formatting
    extend self

    def reason_width(notifications : Array) : Int32
      notifications.max_of?(&.reason.to_s.size) || 0
    end

    def purge_reason_width(notifications : Array(Notification::Purged)) : Int32
      notifications.max_of?(&.purge_reason.to_s.size) || 0
    end

    def colourised_reason(reason : GitHub::NotificationReason, width : Int32) : String
      padded = reason.to_s.ljust(width)

      case reason
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

    def colourised_purge_reason(reason : PurgeReason, width : Int32) : String
      padded = reason.to_s.ljust(width)

      case reason
      in .merged?
        padded.colorize.light_magenta
      in .closed?
        padded.colorize.red
      in .filtered?
        padded.colorize.dark_gray
      end.to_s
    end
  end
end
