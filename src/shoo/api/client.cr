require "http/client"
require "json"

module Shoo
  module API
    class Client
      HTTPS       = "https"
      GITHUB_HOST = "api.github.com"
      BASE_URL    = "#{HTTPS}://#{GITHUB_HOST}"

      alias TBody = Hash(String, String)

      def initialize(@token : String); end

      def notifications : Notifications
        Notifications.new(self)
      end

      def pull_requests : PullRequests
        PullRequests.new(self)
      end

      def issues : Issues
        Issues.new(self)
      end

      def teams : Teams
        Teams.new(self)
      end

      def get(type : T.class, path : String, query : TBody = TBody.new) : API::Result(T) forall T
        {% unless T.class.has_method?("from_json") %}
          {% raise "Type #{T} must include JSON::Serializable" %}
        {% end %}

        response = HTTP::Client.get(build_uri(path, query), headers: headers)
        API::Result(T).from(response)
      end

      def get_from_url(type : T.class, url : String) : API::Result(T) forall T
        path = url.sub(BASE_URL, "")
        get(type, path)
      end

      def patch(type : T.class, path : String) : API::Result(T) forall T
        {% unless T.class.has_method?("from_json") %}
          {% raise "Type #{T} must include JSON::Serializable" %}
        {% end %}

        response = HTTP::Client.patch("#{BASE_URL}#{path}", headers: headers)
        API::Result(T).from(response)
      end

      def delete(path : String) : Bool
        response = HTTP::Client.delete("#{BASE_URL}#{path}", headers: headers)
        response.success?
      end

      private def headers
        HTTP::Headers{
          "Authorization"        => "Bearer #{@token}",
          "X-GitHub-Api-Version" => "2022-11-28",
        }
      end

      private def build_uri(path : String, query : TBody = TBody.new) : URI
        params = URI::Params.encode(query)
        URI.new(HTTPS, GITHUB_HOST, path: path, query: params)
      end
    end
  end
end
