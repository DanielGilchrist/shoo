require "json"

module Shoo
  module GitHub
    struct Comment
      include JSON::Serializable

      getter body : String
    end
  end
end
