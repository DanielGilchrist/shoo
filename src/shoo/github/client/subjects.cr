require "../queries/issue_or_pull_request_fragment"
require "../queries/issue_or_pull_request_with_reviewers_fragment"
require "../queries/issue_or_pull_request_comments_fragment"

module Shoo
  module GitHub
    struct Client
      struct Subjects
        CLOSED = "CLOSED"

        alias Fragment = Queries::IssueOrPullRequestFragment
        alias WithReviewersFragment = Queries::IssueOrPullRequestWithReviewersFragment
        alias CommentsFragment = Queries::IssueOrPullRequestCommentsFragment
        alias Reviewer = WithReviewersFragment::PullRequest::ReviewRequests::Nodes::RequestedReviewer

        alias Outcome = Subject::Any | Unresolved
        alias Outcomes = Hash(SubjectRef, Outcome)
        alias CommentsOutcome = Array(String) | Unresolved
        alias CommentsOutcomes = Hash(SubjectRef, CommentsOutcome)

        def initialize(@graphql : ::GraphQL::Client) : Nil
        end

        def fetch(refs : Array(SubjectRef), *, with_reviewers : Bool) : Outcomes | ::GraphQL::Failure
          return fetch_with_reviewers(refs) if with_reviewers

          case fetched = Batch(Fragment).new(@graphql).fetch(refs)
          in ::GraphQL::Failure then fetched
          in Hash               then fetched.transform_values { |outcome| outcome.is_a?(Unresolved) ? outcome : subject(outcome) }
          end
        end

        private def fetch_with_reviewers(refs : Array(SubjectRef)) : Outcomes | ::GraphQL::Failure
          case fetched = Batch(WithReviewersFragment).new(@graphql).fetch(refs)
          in ::GraphQL::Failure then fetched
          in Hash               then fetched.transform_values { |outcome| outcome.is_a?(Unresolved) ? outcome : subject(outcome) }
          end
        end

        def comments(refs : Array(SubjectRef)) : CommentsOutcomes | ::GraphQL::Failure
          case fetched = Batch(CommentsFragment).new(@graphql).fetch(refs)
          in ::GraphQL::Failure then fetched
          in Hash               then fetched.transform_values { |outcome| outcome.is_a?(Unresolved) ? outcome : bodies(outcome) }
          end
        end

        private def subject(fragment : Fragment) : Outcome
          case node = fragment.variant
          in Fragment::PullRequest
            Subject::PullRequest.new(node.id, node.author.try(&.login), node.merged, node.merged_at, node.state == CLOSED, node.closed_at, [] of String)
          in Fragment::Issue
            Subject::Issue.new(node.id, node.author.try(&.login), node.state == CLOSED, node.closed_at)
          in Fragment::Unknown
            Unresolved.new("unexpected subject type #{node.typename}")
          end
        end

        private def subject(fragment : WithReviewersFragment) : Outcome
          case node = fragment.variant
          in WithReviewersFragment::PullRequest
            Subject::PullRequest.new(node.id, node.author.try(&.login), node.merged, node.merged_at, node.state == CLOSED, node.closed_at, requested_team_slugs(node))
          in WithReviewersFragment::Issue
            Subject::Issue.new(node.id, node.author.try(&.login), node.state == CLOSED, node.closed_at)
          in WithReviewersFragment::Unknown
            Unresolved.new("unexpected subject type #{node.typename}")
          end
        end

        private def requested_team_slugs(node : WithReviewersFragment::PullRequest) : Array(String)
          node.review_requests.nodes.compact_map do |request|
            case reviewer = request.requested_reviewer.try(&.variant)
            in Reviewer::Team    then reviewer.slug
            in Reviewer::Unknown then nil
            in Nil               then nil
            end
          end
        end

        private def bodies(fragment : CommentsFragment) : Array(String)
          case node = fragment.variant
          in CommentsFragment::PullRequest
            node.comments.nodes.map(&.body) + node.reviews.nodes.flat_map { |review| [review.body] + review.comments.nodes.map(&.body) }
          in CommentsFragment::Issue
            node.comments.nodes.map(&.body)
          in CommentsFragment::Unknown
            [] of String
          end
        end
      end
    end
  end
end
