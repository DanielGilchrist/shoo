module Shoo
  class Config
    struct Raw
      struct Notifications
        include YAML::Serializable

        getter purge : Purge = Purge.new

        def initialize
        end
      end
    end
  end
end
