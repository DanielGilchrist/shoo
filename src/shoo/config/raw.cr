module Shoo
  struct Config
    struct Raw
      include YAML::Serializable

      def self.parse(content : String?) : Raw
        return new if content.nil? || content.blank?

        from_yaml(content)
      end

      getter notifications : Notifications = Notifications.new
      getter github : Github = Github.new

      private def initialize
      end
    end
  end
end
