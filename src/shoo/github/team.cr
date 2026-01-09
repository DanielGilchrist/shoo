require "json"

module Shoo
  module GitHub
    struct Team
      include JSON::Serializable

      getter slug : String
    end
  end
end
