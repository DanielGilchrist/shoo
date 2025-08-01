require "json"

module Shoo
  module API
    struct User
      include JSON::Serializable

      getter login : String
    end
  end
end
