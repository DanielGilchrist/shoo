module Shoo
  module GitHub
    struct Client
      struct Teams
        alias Members = Array(String)

        def initialize(@graphql : ::GraphQL::Client) : Nil
        end

        def members(organisation_name : String, team_slug : String) : Members | Unresolved | ::GraphQL::Failure
          MembersPager.new(@graphql).members(organisation_name, team_slug)
        end
      end
    end
  end
end
