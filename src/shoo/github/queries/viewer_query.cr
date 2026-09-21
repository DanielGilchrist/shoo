module Shoo
  module GitHub
    module Queries
      # https://docs.github.com/en/graphql/reference/queries#viewer
      ::GraphQL.query ViewerQuery do
        viewer do
          login String
        end
      end
    end
  end
end
