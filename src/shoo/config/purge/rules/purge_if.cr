module Shoo
  class Config
    struct Purge
      struct Rules
        struct PurgeIf
          alias RawPurgeIf = Raw::Purge::Rules::PurgeIf

          def self.parse(raw : RawPurgeIf) : PurgeIf | Array(Error)
            errors = [] of Error

            merged_result = StateRule.parse(raw.merged, :merged)
            closed_result = StateRule.parse(raw.closed, :closed)

            errors << merged_result if merged_result.is_a?(Error)
            errors << closed_result if closed_result.is_a?(Error)
            return errors unless errors.empty?

            merged = merged_result.is_a?(StateRule) ? merged_result : nil
            closed = closed_result.is_a?(StateRule) ? closed_result : nil

            new(merged, closed)
          end

          private def initialize(@merged : StateRule?, @closed : StateRule?)
          end

          getter merged : StateRule?
          getter closed : StateRule?

          def applicable? : Bool
            !merged.nil? || !closed.nil?
          end
        end
      end
    end
  end
end
