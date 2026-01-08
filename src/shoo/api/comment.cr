require "json"

module Shoo
  module API
    struct Comment
      include JSON::Serializable

      getter body : String
    end
  end
end
