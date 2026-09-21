module Shoo
  module GitHub
    struct Client
      class GraphQLTransport < ::GraphQL::Transport
        PATH = "/graphql"

        @headers : HTTP::Headers

        def initialize(@pool : ConnectionPool, headers : HTTP::Headers) : Nil
          @headers = headers.dup.merge!(JSON_HEADERS)
        end

        def post(body : String) : HTTP::Client::Response
          @pool.checkout(&.post(PATH, headers: @headers, body: body))
        end
      end
    end
  end
end
