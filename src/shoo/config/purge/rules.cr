module Shoo
  class Config
    struct Purge
      struct Rules
        alias RawRules = Raw::Purge::Rules

        def self.parse(raw : RawRules) : Rules | Array(Error)
          errors = [] of Error

          keep_if_result = KeepIf.parse(raw.keep_if)
          purge_if_result = PurgeIf.parse(raw.purge_if)

          errors.concat(keep_if_result) if keep_if_result.is_a?(Array(Error))
          errors.concat(purge_if_result) if purge_if_result.is_a?(Array(Error))
          return errors unless errors.empty?

          return errors unless keep_if_result.is_a?(KeepIf)
          return errors unless purge_if_result.is_a?(PurgeIf)

          new(keep_if_result, purge_if_result, raw.unsubscribe?)
        end

        private def initialize(@keep_if : KeepIf, @purge_if : PurgeIf, @unsubscribe : Bool)
        end

        getter keep_if : KeepIf
        getter purge_if : PurgeIf
        getter? unsubscribe : Bool
      end
    end
  end
end
