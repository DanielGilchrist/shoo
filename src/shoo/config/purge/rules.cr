module Shoo
  class Config
    class Purge
      class Rules
        include YAML::Serializable

        getter keep_if : KeepIf = KeepIf.new
        getter purge_if : PurgeIf = PurgeIf.new
        getter? unsubscribe : Bool = false

        def initialize
        end
      end
    end
  end
end
