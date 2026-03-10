module Shoo
  class Config
    struct Raw
      struct Purge
        struct Rules
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
end
