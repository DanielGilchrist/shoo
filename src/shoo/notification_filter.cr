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
      return true if notification.always_keep?

      rules = @config.rules_for(notification)
      keep_rules = rules.keep_if

      return true if keep_rules.mentioned? && notification.reason.mention?
      return false unless notification.subject.should_check_author?

      url = notification.subject.url
      return false unless url

      author = authors[url]?
      return false if !author || author.empty?
      return true if keep_rules.authors.includes?(author)
      return true if author_in_teams?(author, keep_rules.author_in_teams, notification.repository)

      false
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
        end.try(&.get(url).ok?.try(&.user.login))
        next if author.nil?

        {url, author}
      end.compact

      results.to_h
    end

    private def author_in_teams?(author : String, teams : Array(String), repository : API::Repository) : Bool
      return false if teams.empty?

      organisation_name = repository.organisation_name

      teams.any? do |team_name|
        team_slug = team_name.downcase.gsub(" ", "-")
        members = @team_cache.fetch(organisation_name, team_slug) do
          @client.teams.members(organisation_name, team_slug).or_default
        end

        members.any? { |member| member.login == author }
      end
    end
  end
end
