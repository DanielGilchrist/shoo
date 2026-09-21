module Shoo
  module GitHub
    struct Client
      struct Users
        SCOPES_HEADER = "X-OAuth-Scopes"

        def initialize(@graphql : ::GraphQL::Client) : Nil
        end

        def identity : Identity | ::GraphQL::Failure
          case envelope = @graphql.execute(Queries::ViewerQuery)
          in ::GraphQL::Envelope(Queries::ViewerQuery) then Identity.new(envelope.data.viewer.login, Scopes.parse(envelope.headers[SCOPES_HEADER]?))
          in ::GraphQL::Failure                        then envelope
          end
        end
      end
    end
  end
end
