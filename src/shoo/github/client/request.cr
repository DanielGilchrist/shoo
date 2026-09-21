module Shoo
  module GitHub
    struct Client
      struct Request
        @headers : HTTP::Headers
        @pool : ConnectionPool

        alias TBody = Hash(String, String)

        GITHUB_HOST = "api.github.com"

        def initialize(token : Token) : Nil
          @headers = build_headers(token)
          @pool = ConnectionPool.new(GITHUB_HOST)
        end

        def get(type : T.class, path : String, query : TBody = TBody.new) : Fetched(T) | Error forall T
          response = @pool.checkout { |client| client.get(full_path(path, query), headers: @headers) }
          return Error.from_json(response.body) unless response.success?

          Fetched(T).new(T.from_json(response.body), response.headers)
        end

        def delete(path : String) : Error?
          response = @pool.checkout(&.delete(path, headers: @headers))
          Error.from_json(response.body) unless response.success?
        end

        def graphql : ::GraphQL::Client
          ::GraphQL::Client.new(GraphQLTransport.new(@pool, @headers))
        end

        private def full_path(path : String, query : TBody) : String
          return path if query.empty?

          "#{path}?#{URI::Params.encode(query)}"
        end

        private def build_headers(token : Token) : HTTP::Headers
          HTTP::Headers{
            "Authorization"        => "Bearer #{token.value}",
            "X-GitHub-Api-Version" => "2022-11-28",
          }
        end
      end
    end
  end
end
