module Shoo
  class Config
    struct Raw
      include YAML::Serializable

      CONFIG_PATH = "#{Path.home}/.config/shoo/config.yml"

      def self.load(path : String = CONFIG_PATH) : Raw
        return new unless File.exists?(path)

        File.open(path) { |file| from_yaml(file) }
      end

      getter notifications : Notifications = Notifications.new
      getter github : Github = Github.new

      private def initialize
      end
    end
  end
end
