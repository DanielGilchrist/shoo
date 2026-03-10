module Shoo
  class Config
    struct Raw
      struct Github
        include YAML::Serializable

        @[YAML::Field(key: "token")]
        getter config_token : String?

        def initialize
        end
      end
    end
  end
end
