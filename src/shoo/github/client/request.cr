module Shoo
  module GitHub
    struct Client
      struct Request
        @headers : HTTP::Headers
        @pool : ConnectionPool

        alias TBody = Hash(String, String)

        HTTPS       = "https"
        GITHUB_HOST = "api.github.com"
        BASE_URL    = "#{HTTPS}://#{GITHUB_HOST}"

        def initialize(token : Token)
          @headers = build_headers(token)
          @pool = ConnectionPool.new(GITHUB_HOST)
        end

        def get(type : T.class, path : String, query : TBody = TBody.new) : Result(T) forall T
          response = @pool.checkout { |client| client.get(full_path(path, query), headers: @headers) }
          Result(T).from(response)
        end

        def get_from_url(type : T.class, url : String) : Result(T) forall T
          path = url.sub(BASE_URL, "")
          get(type, path)
        end

        def identity(path : String = "/user") : Identity | Error
          response = @pool.checkout(&.get(path, headers: @headers))

          if response.success?
            Identity.new(
              User.from_json(response.body),
              Scopes.parse(response.headers["X-OAuth-Scopes"]?),
            )
          else
            Error.from_json(response.body)
          end
        end

        def delete(path : String) : Bool
          response = @pool.checkout(&.delete(path, headers: @headers))
          response.success?
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
