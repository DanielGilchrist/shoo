require "json"

module Shoo
  module API
    struct PullRequest
      include JSON::Serializable

      getter user : User
      getter title : String
      getter state : String
      getter requested_teams : Array(Team)
      getter review_comments_url : String
      getter comments_url : String
    end
  end
end
