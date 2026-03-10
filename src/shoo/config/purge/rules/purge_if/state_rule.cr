module Shoo
  class Config
    class Purge
      class Rules
        class PurgeIf
          class StateRule
            include YAML::Serializable

            getter? always : Bool = false
            getter after : String? = nil

            def initialize
            end

            def applicable? : Bool
              always? || !after.nil?
            end

            def after_duration : Duration?
              raw = after
              return unless raw

              Duration.parse(raw)
            end
          end
        end
      end
    end
  end
end
