module Shoo
  struct NotificationFilter
    def initialize(@config : Config, @client : API::Client)
      @team_cache = Cache(Array(API::User)).new
    end

    def filter(notifications : Array(API::Notification)) : {Array(API::Notification), Array(API::Notification)}
      authors = fetch_authors_concurrently(notifications)

      notifications.partition do |notification|
        should_keep?(notification, authors)
      end
    end

    private def should_keep?(notification : API::Notification, authors : Hash(String, String)) : Bool
      rules = rules_for_repo(notification.repository.full_name)
      keep_rules = rules.keep_if

      return true if keep_rules.mentioned? && notification.reason.mention?
      return true if notification.authored?
      return false unless notification.subject.should_check_author?

      url = notification.subject.url
      return false unless url

      author = authors[url]?
      return false if !author || author.empty?
      return true if keep_rules.authors.includes?(author)
      return true if author_in_teams?(author, keep_rules.author_in_teams, notification.repository.full_name)

      false
    end

    private def rules_for_repo(repo_name : String) : PurgeRules
      @config.notifications.purge.repos[repo_name]? || @config.notifications.purge.global
    end

    private def fetch_authors_concurrently(notifications : Array(API::Notification)) : Hash(String, String)
      urls_to_fetch = notifications.compact_map do |notification|
        next unless notification.subject.should_check_author?
        next if notification.authored?

        notification.subject.url
      end.uniq!

      results = ConcurrentWorker.run(urls_to_fetch) do |url|
        author = begin
          case url
          when /\/pulls\/\d+$/
            @client.pull_requests
          when /\/issues\/\d+$/
            @client.issues
          end
        end.try(&.get(url).map_or(nil, &.user.login))
        next if author.nil?

        # TODO: Figure out why this cast is necessary (Crystal thinks `NoReturn`)
        {url, author.as(String)}
      end.compact

      results.to_h
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
