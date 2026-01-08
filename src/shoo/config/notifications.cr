module Shoo
  class Config
    class Notifications
      include YAML::Serializable

      getter purge : Purge = Purge.new

      def initialize
      end
    end
  end
end
