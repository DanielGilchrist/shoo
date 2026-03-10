module Shoo
  class Config
    struct Raw
      struct Purge
        struct Rules
          struct PurgeIf
            struct StateRule
              include YAML::Serializable

              getter? always : Bool = false
              getter after : String? = nil

              def initialize
              end
            end
          end
        end
      end
    end
  end
end
