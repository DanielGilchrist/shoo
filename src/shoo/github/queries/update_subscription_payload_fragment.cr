module Shoo
  module GitHub
    module Queries
      # https://docs.github.com/en/graphql/reference/mutations#updatesubscription
      ::GraphQL.fragment UpdateSubscriptionPayloadFragment do
        clientMutationId String?
      end
    end
  end
end
