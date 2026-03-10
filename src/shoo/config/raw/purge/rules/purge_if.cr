module Shoo
  class Config
    struct Raw
      struct Purge
        struct Rules
          struct PurgeIf
            include YAML::Serializable

            getter merged : StateRule = StateRule.new
            getter closed : StateRule = StateRule.new

            def initialize
            end
          end
        end
      end
    end
  end
end
