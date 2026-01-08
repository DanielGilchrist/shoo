module Shoo
  class Config
    class Purge
      include YAML::Serializable

      class Rules
        include YAML::Serializable

        class Keep
          include YAML::Serializable

          getter author_in_teams : Array(String) = [] of String
          getter requested_teams : Array(String) = [] of String
          getter mentioned_teams : Array(String) = [] of String
          getter authors : Array(String) = [] of String
          getter? mentioned : Bool = false
          getter labels : Array(String) = [] of String
          getter pr_states : Array(String) = [] of String

          def initialize
          end
        end

        getter keep_if : Keep = Keep.new
        getter? unsubscribe : Bool = false

        def initialize
        end
      end

      getter global : Rules = Rules.new
      getter repos : Hash(String, Rules) = Hash(String, Rules).new

      def initialize
      end
    end
  end
end
