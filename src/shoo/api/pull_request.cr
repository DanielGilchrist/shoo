require "json"

module Shoo
  module API
    struct PullRequest
      include JSON::Serializable

      getter user : User
      getter title : String
      getter state : String
    end
  end
end
