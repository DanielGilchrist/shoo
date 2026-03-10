module Shoo
  class Config
    class Purge
      include YAML::Serializable

      getter global : Rules = Rules.new
      getter repos : Hash(String, Rules) = Hash(String, Rules).new

      def initialize
      end
    end
  end
end
