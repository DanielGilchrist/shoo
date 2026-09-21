module Shoo
  module GitHub
    module Queries
      # https://docs.github.com/en/graphql/reference/unions#issueorpullrequest
      ::GraphQL.fragment IssueOrPullRequestFragment do
        on PullRequest do
          state String
          merged Bool
          mergedAt Time?
          closedAt Time?
          author? { login String }
          reviewRequests(first: 20) do
            nodes Array do
              requestedReviewer? do
                on Team do
                  slug String
                end
              end
            end
          end
        end

        on Issue do
          state String
          closedAt Time?
          author? { login String }
        end
      end
    end
  end
end
