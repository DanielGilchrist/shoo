require "json"

module Shoo
  module API
    struct Team
      include JSON::Serializable

      getter slug : String
    end
  end
end
