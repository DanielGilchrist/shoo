module Shoo
  module GitHub
    struct Client
      struct Teams
        def initialize(@request : Request)
        end

        def members(organisation_name : String, team_slug : String) : Result(Array(User))
          @request.get(Array(User), "/orgs/#{organisation_name}/teams/#{team_slug}/members")
        end
      end
    end
  end
end
