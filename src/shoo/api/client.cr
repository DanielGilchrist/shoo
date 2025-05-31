require "http/client"
require "json"
require "./result"
require "./notification"
require "./notifications"

module Shoo
  module API
    class Client
      BASE_URL = "https://api.github.com"

      def initialize(@token : String)
      end

      def notifications : Notifications
        Notifications.new(self)
      end

      def get(type : T.class, path : String) : API::Result(T) forall T
        {% unless T.class.has_method?("from_json") %}
          {% raise "Type #{T} must include JSON::Serializable" %}
        {% end %}

        response = http_client.get(path, headers)
        API::Result.new((response.success? ? T : GitHubError).from_json(response.body))
      end

      private def http_client
        @http_client ||= HTTP::Client.new(URI.parse(BASE_URL))
      end

      private def headers
        HTTP::Headers{
          "Authorization" => "Bearer #{@token}",
          "X-GitHub-Api-Version" => "2022-11-28"
        }
      end
    end
  end
end
