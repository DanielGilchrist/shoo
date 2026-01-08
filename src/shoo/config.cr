require "yaml"

module Shoo
  class Config
    include YAML::Serializable

    CONFIG_DIR = "#{Path.home}/.config/shoo/config.yml"

    def self.load(path : String = CONFIG_DIR) : Config | Array(Error)
      return new unless File.exists?(path)

      config = from_yaml(File.read(path))
      errors = Validator.run(config)
      return errors if errors.any?

      config
    end

    getter notifications : Notifications = Notifications.new
    getter github : Github = Github.new

    private def initialize
    end

    def purge_rules_for(notification : API::Notification) : Purge::Rules
      notifications.purge.repos[notification.repository_name]? || notifications.purge.global
    end
  end
end
