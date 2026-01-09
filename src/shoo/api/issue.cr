require "json"

module Shoo
  module API
    struct Issue
      include JSON::Serializable

      getter user : User
      getter title : String
      getter state : String
      getter comments_url : String
    end
  end
end
