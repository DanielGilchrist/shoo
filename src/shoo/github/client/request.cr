module Shoo
  module GitHub
    struct Client
      struct Request
        @headers : HTTP::Headers

        alias TBody = Hash(String, String)

        HTTPS       = "https"
        GITHUB_HOST = "api.github.com"
        BASE_URL    = "#{HTTPS}://#{GITHUB_HOST}"

        def initialize(token : String)
          @headers = build_headers(token)
        end

        def get(type : T.class, path : String, query : TBody = TBody.new) : Result(T) forall T
          response = HTTP::Client.get(build_uri(path, query), headers: @headers)
          Result(T).from(response)
        end

        def get_from_url(type : T.class, url : String) : Result(T) forall T
          path = url.sub(BASE_URL, "")
          get(type, path)
        end

        def delete(path : String) : Bool
          response = HTTP::Client.delete("#{BASE_URL}#{path}", headers: @headers)
          response.success?
        end

        private def build_uri(path : String, query : TBody = TBody.new) : URI
          params = URI::Params.encode(query)
          URI.new(HTTPS, GITHUB_HOST, path: path, query: params)
        end

        private def build_headers(token : String) : HTTP::Headers
          HTTP::Headers{
            "Authorization"        => "Bearer #{token}",
            "X-GitHub-Api-Version" => "2022-11-28",
          }
        end
      end
    end
  end
end
