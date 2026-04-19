module Shoo
  class Config
    struct Purge
      struct Rules
        struct PurgeIf
          abstract struct StateRule
            alias Kind = Error::StateRuleError::Kind
            alias RawStateRule = Raw::Purge::Rules::PurgeIf::StateRule

            def self.parse(raw : RawStateRule, kind : Kind) : StateRule? | Error
              if raw.always? && raw.after
                return Error::StateRuleError.mutually_exclusive(kind)
              end

              return Always.new if raw.always?

              after = raw.after
              return unless after

              duration = Duration.parse?(after)
              return Error::StateRuleError.invalid_duration(kind, after) unless duration

              After.new(duration)
            end

            struct Always < StateRule
            end

            struct After < StateRule
              def initialize(@duration : Duration)
              end

              getter duration : Duration
            end
          end
        end
      end
    end
  end
end
