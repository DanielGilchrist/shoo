module Shoo
  module API
    class Client
      struct Teams
        def initialize(@client : Client)
        end

        def members(organisation_name : String, team_slug : String) : API::Result(Array(User))
          @client.get(Array(User), "/orgs/#{organisation_name}/teams/#{team_slug}/members")
        end
      end
    end
  end
end
