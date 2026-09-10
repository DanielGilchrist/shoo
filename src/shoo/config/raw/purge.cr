module Shoo
  struct Config
    struct Raw
      struct Purge
        include YAML::Serializable

        getter global : Rules = Rules.new
        getter repos : Hash(String, Rules) = Hash(String, Rules).new

        def initialize : Nil
        end
      end
    end
  end
end
