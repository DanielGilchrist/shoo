module Shoo
  class Config
    module Validator
      extend self

      SLUG_REGEX = /^[a-z0-9_-]+$/

      def run(config : Config) : Array(Error)
        validate_notifications(config)
      end

      private def validate_notifications(config : Config) : Array(Error)
        notification_config = config.notifications
        purge_config = notification_config.purge

        rules = [purge_config.global]
        rules.concat(purge_config.repos.values)

        rules.flat_map { |rule| validate_purge_rules(rule) }
      end

      private def validate_purge_rules(rules : Purge::Rules) : Array(Error)
        keep_if_config = rules.keep_if

        [
          validate_author_in_teams(keep_if_config),
          validate_requested_teams(keep_if_config),
          validate_mentioned_teams(keep_if_config),
        ].flatten
      end

      private def validate_author_in_teams(keep_if_config : Purge::Rules::Keep) : Array(Error)
        keep_if_config.author_in_teams.compact_map do |team_slug|
          Error::SlugError.for(team_slug, :author_in_teams) if invalid_slug?(team_slug)
        end
      end

      private def validate_requested_teams(keep_if_config : Purge::Rules::Keep) : Array(Error)
        keep_if_config.requested_teams.compact_map do |team_slug|
          Error::SlugError.for(team_slug, :requested_teams) if invalid_slug?(team_slug)
        end
      end

      private def validate_mentioned_teams(keep_if_config : Purge::Rules::Keep) : Array(Error)
        keep_if_config.mentioned_teams.compact_map do |team_slug|
          Error::SlugError.for(team_slug, :mentioned_teams) if invalid_slug?(team_slug)
        end
      end

      private def invalid_slug?(maybe_slug : String) : Bool
        !maybe_slug.matches?(SLUG_REGEX)
      end
    end
  end
end
