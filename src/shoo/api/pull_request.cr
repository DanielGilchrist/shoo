require "json"

module Shoo
  module API
    struct PullRequest
      include JSON::Serializable

      property user : User
      property title : String
      property state : String
    end

    struct Issue
      include JSON::Serializable

      property user : User
      property title : String
      property state : String
    end

    struct User
      include JSON::Serializable

      property login : String
    end
  end
end
