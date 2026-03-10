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
    end
  end
end
