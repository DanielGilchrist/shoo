module Shoo
  struct NotificationFilter
    alias Subject = GitHub::PullRequest | GitHub::Issue
    alias SubjectsByUrl = Hash(String, Subject)
    alias CommentsByUrl = Hash(String, Array(GitHub::Comment))
    alias SubjectEndpoint = GitHub::Client::Issues | GitHub::Client::PullRequests
    alias KeepIfRules = Config::Purge::Rules::KeepIf
    alias PurgeIfRules = Config::Purge::Rules::PurgeIf
    alias StateRule = PurgeIfRules::StateRule

    ALWAYS_KEEP_REASONS = {
      GitHub::NotificationReason::Author,
      GitHub::NotificationReason::Subscribed,
      GitHub::NotificationReason::Comment,
      GitHub::NotificationReason::Assign,
      GitHub::NotificationReason::Manual,
    }

    record SubjectAndCommentsUrl, subject_url : String, comments_url : String

    @subjects_by_url : SubjectsByUrl? = nil
    @comments_by_url : CommentsByUrl? = nil

    def initialize(@config : Config, @client : GitHub::Client, @github_notifications : Array(GitHub::Notification))
      @team_cache = Cache(Array(GitHub::User)).new
    end

    def filter : Array(Notification::Any)
      @github_notifications.map do |github_notification|
        case verdict = verdict_for(github_notification)
        in KeepReason
          Notification::Kept.new(github_notification, verdict)
        in PurgeReason
          Notification::Purged.new(github_notification, verdict)
        end
      end
    end

    private def verdict_for(github_notification : GitHub::Notification) : KeepReason | PurgeReason
      rules = @config.purge_rules_for(github_notification.repository.full_name)
      subject = fetch_subject(github_notification)

      if subject
        purge_if_rules = rules.purge_if
        if purge_if_rules.applicable?
          reason = state_purge_reason(subject, purge_if_rules)
          return reason if reason
        end
      end

      return KeepReason::AlwaysKept.new(github_notification.reason) if always_keep?(github_notification)
      return PurgeReason::Filtered unless subject

      keep_rules = rules.keep_if

      return KeepReason::Mentioned.new if keep_rules.mentioned? && github_notification.reason.mention?

      author = subject.user.login
      return KeepReason::Author.new(author) if keep_rules.authors.includes?(author)

      if team = matched_author_team(author, github_notification, keep_rules)
        return KeepReason::AuthorInTeam.new(team)
      end

      if subject.is_a?(GitHub::PullRequest) && (team = matched_requested_team(subject, keep_rules))
        return KeepReason::RequestedTeam.new(team)
      end

      if team = matched_mentioned_team(subject, github_notification, keep_rules)
        return KeepReason::MentionedTeam.new(team)
      end

      PurgeReason::Filtered
    end

    private def fetch_subject(github_notification : GitHub::Notification) : Subject?
      return unless github_notification.subject.should_check_author?

      url = github_notification.subject.url
      return unless url

      subjects_by_url[url]?
    end

    private def state_purge_reason(subject : Subject, purge_if : PurgeIfRules) : PurgeReason?
      case subject
      in GitHub::PullRequest
        pull_request_purge_reason(subject, purge_if)
      in GitHub::Issue
        issue_purge_reason(subject, purge_if)
      end
    end

    private def pull_request_purge_reason(pull_request : GitHub::PullRequest, purge_if : PurgeIfRules) : PurgeReason?
      if pull_request.merged?
        PurgeReason::Merged if state_rule_matches?(purge_if.merged, pull_request.merged_at)
      elsif pull_request.state.closed?
        PurgeReason::Closed if state_rule_matches?(purge_if.closed, pull_request.closed_at)
      end
    end

    private def issue_purge_reason(issue : GitHub::Issue, purge_if : PurgeIfRules) : PurgeReason?
      return unless issue.closed?

      PurgeReason::Closed if state_rule_matches?(purge_if.closed, issue.closed_at)
    end

    private def state_rule_matches?(rule : StateRule?, timestamp : Time?) : Bool
      case rule
      in StateRule::Always
        true
      in StateRule::After
        timestamp ? rule.duration.elapsed_since?(timestamp) : false
      in StateRule, Nil
        false
      end
    end

    private def endpoint_for(subject : GitHub::Subject) : SubjectEndpoint?
      case subject.type
      in .pull_request?
        @client.pull_requests
      in .issue?
        @client.issues
      in .check_suite?, .discussion?, .release?, .repository_dependabot_alerts_thread?
        nil
      end
    end

    private def matched_author_team(author : String, github_notification : GitHub::Notification, keep_rules : KeepIfRules) : String?
      team_slugs = keep_rules.author_in_teams
      return if team_slugs.empty?

      organisation_name = github_notification.repository.organisation_name

      matched = team_slugs.find do |team_slug|
        slug_value = team_slug.value

        members = @team_cache.fetch(organisation_name, slug_value) do
          @client.teams.members(organisation_name, slug_value).unwrap_or { Array(GitHub::User).new }
        end

        members.any? { |member| member.login == author }
      end

      matched.try(&.value)
    end

    private def matched_requested_team(pull_request : GitHub::PullRequest, keep_rules : KeepIfRules) : String?
      matched = keep_rules.requested_teams.find do |team_slug|
        pull_request.requested_teams.any? { |team| team_slug == team.slug }
      end

      matched.try(&.value)
    end

    private def matched_mentioned_team(subject : Subject, github_notification : GitHub::Notification, keep_rules : KeepIfRules) : String?
      return unless github_notification.reason.team_mention?

      mentioned_team_slugs = keep_rules.mentioned_teams
      return if mentioned_team_slugs.empty?

      organisation_name = github_notification.repository.organisation_name
      comments = comments_by_url[github_notification.subject.url]?
      return if comments.nil? || comments.empty?

      matched = mentioned_team_slugs.find do |team_slug|
        comments.any? do |comment|
          contains_team_mention?(comment.body, organisation_name, team_slug.value)
        end
      end

      matched.try(&.value)
    end

    private def always_keep?(github_notification : GitHub::Notification) : Bool
      ALWAYS_KEEP_REASONS.includes?(github_notification.reason)
    end

    private def contains_team_mention?(content : String, organisation_name : String, team_slug : String)
      content.includes?("@#{organisation_name}/#{team_slug}")
    end

    private def comments_by_url : CommentsByUrl
      @comments_by_url ||= fetch_comments_by_url_concurrently
    end

    private def subjects_by_url : SubjectsByUrl
      @subjects_by_url ||= fetch_subjects_by_url_concurrently
    end

    private def fetch_comments_by_url_concurrently : CommentsByUrl
      subject_and_comments_urls = subjects_by_url.flat_map do |url, subject|
        [SubjectAndCommentsUrl.new(url, subject.comments_url)].tap do |result|
          result << SubjectAndCommentsUrl.new(url, subject.review_comments_url) if subject.is_a?(GitHub::PullRequest)
        end
      end

      results = ConcurrentWorker.run(subject_and_comments_urls) do |urls|
        subject_url = urls.subject_url
        comments_url = urls.comments_url

        comments = @client.comments.list(comments_url).ok?
        next if comments.nil? || comments.empty?

        {subject_url, comments}
      end.compact

      results.to_h
    end

    private def needs_subject_fetch?(github_notification : GitHub::Notification) : Bool
      return true unless always_keep?(github_notification)

      rules = @config.purge_rules_for(github_notification.repository.full_name)
      rules.purge_if.applicable?
    end

    private def fetch_subjects_by_url_concurrently : SubjectsByUrl
      notifications_to_fetch = @github_notifications.select(&->needs_subject_fetch?(GitHub::Notification))

      results = ConcurrentWorker.run(notifications_to_fetch) do |github_notification|
        subject = github_notification.subject
        url = subject.url
        next unless url

        endpoint = endpoint_for(subject)
        next unless endpoint

        subject_object = endpoint.get(url).ok?
        next unless subject_object

        {url, subject_object}
      end.compact

      results.to_h
    end
  end
end
