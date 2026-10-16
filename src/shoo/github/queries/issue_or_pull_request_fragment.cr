module Shoo
  module GitHub
    module Queries
      # https://docs.github.com/en/graphql/reference/unions#issueorpullrequest
      ::GraphQL.fragment IssueOrPullRequestFragment do
        on PullRequest do
          id String
          state String
          merged Bool
          mergedAt Time?
          closedAt Time?
          author? { login String }
        end

        on Issue do
          id String
          state String
          closedAt Time?
          author? { login String }
        end
      end
    end
  end
end
