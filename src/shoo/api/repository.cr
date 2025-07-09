module Shoo
  module API
    struct Repository
      include JSON::Serializable

      getter full_name : String
    end
  end
end
