module Shoo
  struct Config
    struct Raw
      struct Notifications
        include YAML::Serializable

        getter purge : Purge = Purge.new

        def initialize : Nil
        end
      end
    end
  end
end
