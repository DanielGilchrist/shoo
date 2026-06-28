module Shoo
  struct Config
    def self.load(store : Store = Store::FileSystem.new) : Config | Array(Error)
      raw = Raw.parse(store.read)

      notifications = Notifications.parse(raw.notifications)
      return notifications if notifications.is_a?(Array(Error))

      github = Github.parse(raw.github)

      new(notifications, github)
    end

    private def initialize(@notifications : Notifications, @github : Github)
    end

    getter notifications : Notifications
    getter github : Github

    def purge_rules_for(repository_name : String) : Purge::Rules
      notifications.purge.repos[repository_name]? || notifications.purge.global
    end
  end
end
