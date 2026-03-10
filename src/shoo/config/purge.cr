module Shoo
  class Config
    struct Purge
      def self.parse(raw : Raw::Purge) : Purge | Array(Error)
        errors = [] of Error

        global_result = Rules.parse(raw.global)

        repos = Hash(String, Rules).new
        raw.repos.each do |name, raw_rules|
          result = Rules.parse(raw_rules)

          if result.is_a?(Array(Error))
            errors.concat(result)
          else
            repos[name] = result
          end
        end

        case global_result
        in Array(Error)
          errors.concat(global_result)
        in Rules
          return new(global_result, repos) if errors.empty?
        end

        errors
      end

      private def initialize(@global : Rules, @repos : Hash(String, Rules))
      end

      getter global : Rules
      getter repos : Hash(String, Rules)
    end
  end
end
