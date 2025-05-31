module Shoo
  struct NotificationFilter
    def initialize(@config : Config, @client : API::Client)
      @author_cache = Cache(String).new
      @team_cache = Cache(Array(API::User)).new
    end

    def should_keep?(notification : API::Notification) : Bool
      rules = rules_for_repo(notification.repository.full_name)
      keep_rules = rules.keep_if

      return true if keep_rules.mentioned_users.any? { |user| notification_mentions_user?(notification, user) }
      return true if notification.authored?
      return false unless notification.subject.should_check_author?

      author = extract_author(notification)
      return false if author.empty?
      return true if keep_rules.authors.includes?(author)
      return true if author_in_teams?(author, keep_rules.author_in_teams, notification.repository.full_name)

      false
    end

    private def rules_for_repo(repo_name : String) : PurgeRules
      @config.notifications.purge.repos[repo_name]? || @config.notifications.purge.global
    end

    private def extract_author(notification : API::Notification) : String
      url = notification.subject.url
      return "" unless url

      @author_cache.fetch(url) do
        case notification.subject.type
        when .pull_request?
          @client.pull_requests.get(url).map_or("") { |pr| pr.user.login }
        when .issue?
          @client.issues.get(url).map_or("") { |issue| issue.user.login }
        else
          ""
        end
      end
    end

    private def notification_mentions_user?(notification : API::Notification, _user : String) : Bool
      notification.reason == "mention"
    end

    private def author_in_teams?(author : String, teams : Array(String), repo_full_name : String) : Bool
      return false if teams.empty?

      org = repo_full_name.split("/").first

      teams.any? do |team_name|
        team_slug = team_name.downcase.gsub(" ", "-")
        cache_key = "#{org}/#{team_slug}"

        members = @team_cache.fetch(cache_key) do
          @client.teams.members(org, team_slug).or_default
        end

        members.any? { |member| member.login == author }
      end
    end
  end
end
