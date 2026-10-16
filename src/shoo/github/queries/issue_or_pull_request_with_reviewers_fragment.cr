module Shoo
  module GitHub
    module Queries
      ::GraphQL.fragment IssueOrPullRequestWithReviewersFragment do
        on PullRequest do
          id String
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
          id String
          state String
          closedAt Time?
          author? { login String }
        end
      end
    end
  end
end
