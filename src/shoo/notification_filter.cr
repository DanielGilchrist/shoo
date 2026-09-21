module Shoo
  class NotificationFilter
    alias Subject = GitHub::Subject::Any
    alias SubjectOutcome = GitHub::Client::Subjects::Outcome
    alias SubjectOutcomes = GitHub::Client::Subjects::Outcomes
    alias CommentsOutcome = GitHub::Client::Subjects::CommentsOutcome
    alias CommentsOutcomes = GitHub::Client::Subjects::CommentsOutcomes
    alias Failure = GitHub::Failure
    alias Verdict = KeepReason | PurgeReason
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

    alias TeamOutcome = GitHub::Client::Teams::Members | GitHub::Unresolved | ::GraphQL::Failure
    alias TeamKey = Tuple(String, String)

    @subjects : (SubjectOutcomes | ::GraphQL::Failure)? = nil
    @comments : (CommentsOutcomes | ::GraphQL::Failure)? = nil

    def initialize(@config : Config, @client : GitHub::Client, @github_notifications : Array(GitHub::Notification)) : Nil
      @teams = Hash(TeamKey, TeamOutcome).new
    end

    def filter : Array(Notification::Any) | Failure
      prefetch
      notifications = Array(Notification::Any).new(@github_notifications.size)

      @github_notifications.each do |github_notification|
        case verdict = verdict_for(github_notification)
        in KeepReason
          notifications << Notification::Kept.new(github_notification, verdict)
        in PurgeReason
          notifications << Notification::Purged.new(github_notification, verdict)
        in Failure
          return verdict
        end
      end

      notifications
    end

    private def verdict_for(github_notification : GitHub::Notification) : Verdict | Failure
      rules = @config.purge_rules_for(github_notification.repository.full_name)

      subject =
        case outcome = subject_outcome_for(github_notification)
        in Nil
          nil
        in ::GraphQL::Failure
          return outcome
        in GitHub::Unresolved
          return unverified(github_notification, outcome.message)
        in Subject
          outcome
        end

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

      if author = subject.author_login
        return KeepReason::Author.new(author) if keep_rules.authors.includes?(author)

        case author_team = matched_author_team(author, github_notification, keep_rules)
        in Nil                then nil
        in String             then return KeepReason::AuthorInTeam.new(author_team)
        in GitHub::Unresolved then return unverified(github_notification, author_team.message)
        in ::GraphQL::Failure then return author_team
        end
      end

      if subject.is_a?(GitHub::Subject::PullRequest) && (requested_team = matched_requested_team(subject, keep_rules))
        return KeepReason::RequestedTeam.new(requested_team)
      end

      case mentioned_team = matched_mentioned_team(github_notification, keep_rules)
      in Nil                then PurgeReason::Filtered
      in String             then KeepReason::MentionedTeam.new(mentioned_team)
      in GitHub::Unresolved then unverified(github_notification, mentioned_team.message)
      in ::GraphQL::Failure then mentioned_team
      end
    end

    # Subjects and team rosters are independent, so their round trips overlap.
    private def prefetch : Nil
      subjects_done = Channel(Nil).new(1)
      spawn do
        subjects_by_ref
      ensure
        subjects_done.send(nil)
      end

      rosters = ConcurrentWorker.run(team_keys) { |(organisation_name, slug)| {organisation_name, slug, @client.teams.members(organisation_name, slug)} }
      rosters.each { |(organisation_name, slug, outcome)| @teams[{organisation_name, slug}] = outcome }

      subjects_done.receive
    end

    private def team_keys : Array(TeamKey)
      @github_notifications.flat_map do |github_notification|
        organisation_name = github_notification.repository.organisation_name
        rules = @config.purge_rules_for(github_notification.repository.full_name)
        rules.keep_if.author_in_teams.map { |team_slug| {organisation_name, team_slug.value} }
      end.uniq!
    end

    private def unverified(github_notification : GitHub::Notification, message : String) : KeepReason
      return KeepReason::AlwaysKept.new(github_notification.reason) if always_keep?(github_notification)

      KeepReason::Unverified.new(message)
    end

    private def state_purge_reason(subject : Subject, purge_if : PurgeIfRules) : PurgeReason?
      case subject
      in GitHub::Subject::PullRequest
        pull_request_purge_reason(subject, purge_if)
      in GitHub::Subject::Issue
        issue_purge_reason(subject, purge_if)
      end
    end

    private def pull_request_purge_reason(pull_request : GitHub::Subject::PullRequest, purge_if : PurgeIfRules) : PurgeReason?
      if pull_request.merged?
        PurgeReason::Merged if state_rule_matches?(purge_if.merged, pull_request.merged_at)
      elsif pull_request.closed?
        PurgeReason::Closed if state_rule_matches?(purge_if.closed, pull_request.closed_at)
      end
    end

    private def issue_purge_reason(issue : GitHub::Subject::Issue, purge_if : PurgeIfRules) : PurgeReason?
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

    private def matched_author_team(author : String, github_notification : GitHub::Notification, keep_rules : KeepIfRules) : String | GitHub::Unresolved | ::GraphQL::Failure | Nil
      organisation_name = github_notification.repository.organisation_name

      keep_rules.author_in_teams.each do |team_slug|
        slug = team_slug.value

        case members = @teams[{organisation_name, slug}]? || GitHub::Unresolved.new("team #{organisation_name}/#{slug} was not fetched")
        in GitHub::Unresolved, ::GraphQL::Failure then return members
        in GitHub::Client::Teams::Members         then return slug if members.includes?(author)
        end
      end

      nil
    end

    private def matched_requested_team(pull_request : GitHub::Subject::PullRequest, keep_rules : KeepIfRules) : String?
      requested_slugs = pull_request.requested_team_slugs
      matched = keep_rules.requested_teams.find { |team_slug| requested_slugs.any? { |slug| team_slug == slug } }
      matched.try(&.value)
    end

    private def matched_mentioned_team(github_notification : GitHub::Notification, keep_rules : KeepIfRules) : String | GitHub::Unresolved | ::GraphQL::Failure | Nil
      return unless mentions_team?(github_notification, keep_rules)

      bodies =
        case outcome = comments_outcome_for(github_notification)
        in Nil                                    then return
        in GitHub::Unresolved, ::GraphQL::Failure then return outcome
        in Array(String)                          then outcome
        end

      organisation_name = github_notification.repository.organisation_name

      matched = keep_rules.mentioned_teams.find do |team_slug|
        bodies.any? { |body| contains_team_mention?(body, organisation_name, team_slug.value) }
      end

      matched.try(&.value)
    end

    private def mentions_team?(github_notification : GitHub::Notification, keep_rules : KeepIfRules) : Bool
      github_notification.reason.team_mention? && !keep_rules.mentioned_teams.empty?
    end

    private def always_keep?(github_notification : GitHub::Notification) : Bool
      ALWAYS_KEEP_REASONS.includes?(github_notification.reason)
    end

    private def contains_team_mention?(content : String, organisation_name : String, team_slug : String) : Bool
      content.includes?("@#{organisation_name}/#{team_slug}")
    end

    private def subject_outcome_for(github_notification : GitHub::Notification) : SubjectOutcome | ::GraphQL::Failure | Nil
      case ref = ref_for(github_notification)
      in Nil                then nil
      in GitHub::Unresolved then ref
      in GitHub::SubjectRef
        subjects = subjects_by_ref
        return subjects if subjects.is_a?(::GraphQL::Failure)

        subjects[ref]?
      end
    end

    private def comments_outcome_for(github_notification : GitHub::Notification) : CommentsOutcome | ::GraphQL::Failure | Nil
      case ref = ref_for(github_notification)
      in Nil                then nil
      in GitHub::Unresolved then ref
      in GitHub::SubjectRef
        comments = comments_by_ref
        return comments if comments.is_a?(::GraphQL::Failure)

        comments[ref]?
      end
    end

    private def ref_for(github_notification : GitHub::Notification) : GitHub::SubjectRef | GitHub::Unresolved | Nil
      subject = github_notification.subject
      return unless subject.should_check_author?

      url = subject.url
      return unless url

      GitHub::SubjectRef.for(github_notification) || GitHub::Unresolved.new("no subject number in #{url}")
    end

    private def subjects_by_ref : SubjectOutcomes | ::GraphQL::Failure
      @subjects ||= @client.subjects.fetch(refs_where { |github_notification| needs_subject_fetch?(github_notification) })
    end

    private def comments_by_ref : CommentsOutcomes | ::GraphQL::Failure
      @comments ||= @client.subjects.comments(refs_where { |github_notification| needs_comments_fetch?(github_notification) })
    end

    private def refs_where(& : GitHub::Notification -> Bool) : Array(GitHub::SubjectRef)
      @github_notifications.compact_map do |github_notification|
        next unless yield github_notification

        ref_for(github_notification).as?(GitHub::SubjectRef)
      end
    end

    private def needs_subject_fetch?(github_notification : GitHub::Notification) : Bool
      return true unless always_keep?(github_notification)

      rules = @config.purge_rules_for(github_notification.repository.full_name)
      rules.purge_if.applicable?
    end

    private def needs_comments_fetch?(github_notification : GitHub::Notification) : Bool
      rules = @config.purge_rules_for(github_notification.repository.full_name)
      mentions_team?(github_notification, rules.keep_if)
    end
  end
end
