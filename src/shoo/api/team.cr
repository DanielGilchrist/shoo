require "json"

module Shoo
  module API
    struct Team
      include JSON::Serializable

      getter name : String
    end
  end
end
