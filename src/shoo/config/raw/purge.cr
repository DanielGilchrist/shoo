module Shoo
  class Config
    struct Raw
      struct Purge
        include YAML::Serializable

        getter global : Rules = Rules.new
        getter repos : Hash(String, Rules) = Hash(String, Rules).new

        def initialize
        end
      end
    end
  end
end
