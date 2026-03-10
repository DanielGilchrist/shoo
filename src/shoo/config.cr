module Shoo
  class Config
    def self.load(path : String = Raw::CONFIG_PATH) : Config | Array(Error)
      raw = Raw.load(path)

      notifications = Notifications.parse(raw.notifications)
      return notifications if notifications.is_a?(Array(Error))

      github = Github.parse(raw.github)

      new(notifications, github)
    end

    private def initialize(@notifications : Notifications, @github : Github)
    end

    getter notifications : Notifications
    getter github : Github

    def purge_rules_for(notification : GitHub::Notification) : Purge::Rules
      notifications.purge.repos[notification.repository_name]? || notifications.purge.global
    end
  end
end
