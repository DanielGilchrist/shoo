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
        [
          validate_keep_if(rules.keep_if),
          validate_purge_if(rules.purge_if),
        ].flatten
      end

      # keep_if validations

      private def validate_keep_if(keep_if : Purge::Rules::KeepIf) : Array(Error)
        [
          validate_slugs(keep_if.author_in_teams, :author_in_teams),
          validate_slugs(keep_if.requested_teams, :requested_teams),
          validate_slugs(keep_if.mentioned_teams, :mentioned_teams),
        ].flatten
      end

      private def validate_slugs(team_slugs : Array(String), kind : Error::SlugError::Kind) : Array(Error)
        team_slugs.compact_map do |team_slug|
          Error::SlugError.for(team_slug, kind) unless team_slug.matches?(SLUG_REGEX)
        end
      end

      # purge_if validations

      private def validate_purge_if(purge_if : Purge::Rules::PurgeIf) : Array(Error)
        [
          validate_state_rule(purge_if.merged, :merged),
          validate_state_rule(purge_if.closed, :closed),
        ].flatten
      end

      private def validate_state_rule(rule : Purge::Rules::PurgeIf::StateRule, kind : Error::StateRuleError::Kind) : Array(Error)
        errors = [] of Error

        if rule.always? && rule.after
          errors << Error::StateRuleError.mutually_exclusive(kind)
        end

        if (after = rule.after) && rule.after_duration.nil?
          errors << Error::StateRuleError.invalid_duration(kind, after)
        end

        errors
      end
    end
  end
end
