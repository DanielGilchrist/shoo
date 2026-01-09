module Shoo
  class Config
    include YAML::Serializable

    CONFIG_DIR = "#{Path.home}/.config/shoo/config.yml"

    def self.load(path : String = CONFIG_DIR) : Config | Array(Error)
      return new unless File.exists?(path)

      config = File.open(path) { |file| from_yaml(file) }
      errors = Validator.run(config)
      return errors unless errors.empty?

      config
    end

    getter notifications : Notifications = Notifications.new
    getter github : Github = Github.new

    private def initialize
    end

    def purge_rules_for(notification : GitHub::Notification) : Purge::Rules
      notifications.purge.repos[notification.repository_name]? || notifications.purge.global
    end
  end
end
