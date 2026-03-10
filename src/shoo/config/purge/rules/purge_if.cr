module Shoo
  class Config
    class Purge
      class Rules
        class PurgeIf
          include YAML::Serializable

          getter merged : StateRule = StateRule.new
          getter closed : StateRule = StateRule.new

          def initialize
          end

          def applicable? : Bool
            merged.applicable? || closed.applicable?
          end
        end
      end
    end
  end
end
