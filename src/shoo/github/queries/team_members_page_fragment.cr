module Shoo
  module GitHub
    module Queries
      # https://docs.github.com/en/graphql/reference/objects#teammemberconnection
      ::GraphQL.fragment TeamMembersPageFragment do
        pageInfo do
          hasNextPage Bool
          endCursor String?
        end
        nodes Array do
          login String
        end
      end
    end
  end
end
