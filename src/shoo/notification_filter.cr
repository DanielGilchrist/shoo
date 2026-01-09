module Shoo
  struct NotificationFilter
    alias Subject = API::PullRequest | API::Issue
    alias SubjectsByUrl = Hash(String, Subject)
    alias SubjectEndpoint = API::Client::Issues | API::Client::PullRequests
    alias KeepRules = Config::Purge::Rules::Keep

    def initialize(@config : Config, @client : API::Client)
      @team_cache = Cache(Array(API::User)).new
    end

    def filter(notifications : Array(API::Notification)) : {Array(API::Notification), Array(API::Notification)}
      subjects_by_url = fetch_subjects_by_url_concurrently(notifications)

      notifications.partition do |notification|
        should_keep?(notification, subjects_by_url)
      end
    end

    private def should_keep?(notification : API::Notification, subjects_by_url : SubjectsByUrl) : Bool
      return true if notification.always_keep?

      rules = @config.purge_rules_for(notification)
      keep_rules = rules.keep_if

      return true if keep_rules.mentioned? && notification.reason.mention?
      return false unless notification.subject.should_check_author?

      url = notification.subject.url
      return false unless url

      subject = subjects_by_url[url]?
      return false unless subject

      author = subject.user.login
      return true if author_in_teams?(author, notification, keep_rules)
      return true if requested_teams?(subject, keep_rules)
      return true if team_mentioned?(subject, notification, keep_rules)

      false
    end

    private def fetch_subjects_by_url_concurrently(notifications : Array(API::Notification)) : SubjectsByUrl
      notifications_to_fetch = notifications.reject(&.always_keep?)

      results = ConcurrentWorker.run(notifications_to_fetch) do |notification|
        subject = notification.subject
        url = subject.url
        next unless url

        endpoint = endpoint_for(subject)
        next unless endpoint

        subject_object = endpoint.get(url).or { nil }
        next unless subject_object

        {url, subject_object}
      end.compact

      results.to_h
    end

    private def endpoint_for(subject : API::Subject) : SubjectEndpoint?
      case subject.type
      when .pull_request?
        @client.pull_requests
      when .issue?
        @client.issues
      end
    end

    private def author_in_teams?(author : String, notification : API::Notification, keep_rules : KeepRules) : Bool
      team_slugs = keep_rules.author_in_teams
      return false if team_slugs.empty?

      organisation_name = notification.repository.organisation_name

      team_slugs.any? do |team_slug|
        members = @team_cache.fetch(organisation_name, team_slug) do
          @client.teams.members(organisation_name, team_slug).or_default
        end

        members.any? { |member| member.login == author }
      end
    end

    private def requested_teams?(subject : Subject, keep_rules : KeepRules) : Bool
      teams = subject.requested_teams
      team_slugs = keep_rules.requested_teams

      teams.any? do |team|
        team_slugs.any? { |team_slug| team_slug == team.slug }
      end
    end

    private def team_mentioned?(subject : Subject, notification : API::Notification, keep_rules : KeepRules) : Bool
      return false unless notification.team_mentioned?

      mentioned_team_slugs = keep_rules.mentioned_teams
      return false if mentioned_team_slugs.empty?

      organisation_name = notification.repository.organisation_name

      # TODO: This should be extracted and fetched concurrently
      comments = [subject.comments_url, subject.review_comments_url].flat_map do |comments_url|
        @client.comments.list(comments_url).or_default
      end

      mentioned_team_slugs.any? do |team_slug|
        comments.any? do |comment|
          contains_team_mention?(comment.body, organisation_name, team_slug)
        end
      end
    end

    private def contains_team_mention?(content : String, organisation_name : String, team_slug : String)
      content.includes?("@#{organisation_name}/#{team_slug}")
    end
  end
end
