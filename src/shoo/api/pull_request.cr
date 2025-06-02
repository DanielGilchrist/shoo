require "json"

module Shoo
  module API
    struct PullRequest
      include JSON::Serializable

      getter user : User
      getter title : String
      getter state : String
    end

    struct Issue
      include JSON::Serializable

      getter user : User
      getter title : String
      getter state : String
    end

    struct User
      include JSON::Serializable

      getter login : String
    end
  end
end
