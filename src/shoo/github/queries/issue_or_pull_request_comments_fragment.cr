module Shoo
  module GitHub
    module Queries
      ::GraphQL.fragment IssueOrPullRequestCommentsFragment do
        on PullRequest do
          comments(last: 100) do
            nodes Array do
              body String
            end
          end

          reviews(last: 100) do
            nodes Array do
              body String
              comments(last: 100) do
                nodes Array do
                  body String
                end
              end
            end
          end
        end

        on Issue do
          comments(last: 100) do
            nodes Array do
              body String
            end
          end
        end
      end
    end
  end
end
