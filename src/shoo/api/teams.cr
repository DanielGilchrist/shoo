module Shoo
  module API
    struct Teams
      def initialize(@client : Client)
      end

      def members(org : String, team_slug : String) : API::Result(Array(User))
        @client.get(Array(User), "/orgs/#{org}/teams/#{team_slug}/members")
      end
    end
  end
end
