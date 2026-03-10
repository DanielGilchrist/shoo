module Shoo
  class Config
    class Purge
      class Rules
        class KeepIf
          include YAML::Serializable

          getter author_in_teams : Array(String) = [] of String
          getter requested_teams : Array(String) = [] of String
          getter mentioned_teams : Array(String) = [] of String
          getter authors : Array(String) = [] of String
          getter? mentioned : Bool = false

          def initialize
          end
        end
      end
    end
  end
end
