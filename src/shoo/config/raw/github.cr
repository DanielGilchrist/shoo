module Shoo
  struct Config
    struct Raw
      struct Github
        include YAML::Serializable

        @[YAML::Field(key: "token")]
        getter config_token : String?

        def initialize : Nil
        end
      end
    end
  end
end
