module Shoo
  class Config
    class Error < Exception
      module SlugError
        extend self

        enum Kind
          AuthorInTeams
          RequestedTeams
          MentionedTeams

          def label : String
            case self
            in .author_in_teams?
              "author_in_teams"
            in .requested_teams?
              "requested_teams"
            in .mentioned_teams?
              "mentioned_teams"
            end
          end
        end

        def for(invalid_slug : String, kind : Kind) : Error
          Error.new("\"#{invalid_slug}\" in `#{kind.label}` must be in slug format!")
        end
      end

      module StateRuleError
        extend self

        enum Kind
          Merged
          Closed

          def label : String
            case self
            in .merged?
              "merged"
            in .closed?
              "closed"
            end
          end
        end

        def mutually_exclusive(kind : Kind) : Error
          Error.new("`purge_if.#{kind.label}` cannot have both `always` and `after` set")
        end

        def invalid_duration(kind : Kind, value : String) : Error
          Error.new("`purge_if.#{kind.label}.after` has invalid duration '#{value}'. Expected format: <number><unit> (e.g. 30m, 1h, 2d, 1w)")
        end
      end
    end
  end
end
