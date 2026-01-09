require "json"

module Shoo
  module GitHub
    struct User
      include JSON::Serializable

      getter login : String
    end
  end
end
