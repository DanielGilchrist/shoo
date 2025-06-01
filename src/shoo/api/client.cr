require "http/client"
require "json"

module Shoo
  module API
    class Client
      BASE_URL = "https://api.github.com"

      def initialize(@token : String)
        @base_uri = URI.parse(BASE_URL)
      end

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

      def get(type : T.class, path : String) : API::Result(T) forall T
        {% unless T.class.has_method?("from_json") %}
          {% raise "Type #{T} must include JSON::Serializable" %}
        {% end %}

        response = HTTP::Client.get("#{BASE_URL}#{path}", headers: headers)
        API::Result.new((response.success? ? T : GitHubError).from_json(response.body))
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
        API::Result.new((response.success? ? T : GitHubError).from_json(response.body))
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
    end
  end
end
