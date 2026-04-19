module Shoo
  class Config
    struct Purge
      struct Rules
        struct KeepIf
          alias RawKeepIf = Raw::Purge::Rules::KeepIf

          def self.parse(raw : RawKeepIf) : KeepIf | Array(Error)
            errors = [] of Error

            author_in_teams = parse_slugs(raw.author_in_teams, :author_in_teams, errors)
            requested_teams = parse_slugs(raw.requested_teams, :requested_teams, errors)
            mentioned_teams = parse_slugs(raw.mentioned_teams, :mentioned_teams, errors)

            return errors unless errors.empty?

            new(author_in_teams, requested_teams, mentioned_teams, raw.authors, raw.mentioned?)
          end

          private def self.parse_slugs(raw_slugs : Array(String), kind : Error::SlugError::Kind, errors : Array(Error)) : Array(TeamSlug)
            raw_slugs.each_with_object([] of TeamSlug) do |raw_slug, slugs|
              slug = TeamSlug.parse?(raw_slug)

              if slug
                slugs << slug
              else
                errors << Error::SlugError.for(raw_slug, kind)
              end
            end
          end

          private def initialize(
            @author_in_teams : Array(TeamSlug),
            @requested_teams : Array(TeamSlug),
            @mentioned_teams : Array(TeamSlug),
            @authors : Array(String),
            @mentioned : Bool,
          )
          end

          getter author_in_teams : Array(TeamSlug)
          getter requested_teams : Array(TeamSlug)
          getter mentioned_teams : Array(TeamSlug)
          getter authors : Array(String)
          getter? mentioned : Bool
        end
      end
    end
  end
end
