require "json"

module Shoo
  struct Notification
    include JSON::Serializable

    property id : String
    property reason : String
    property subject : Subject
    property repository : Repository
  end

  struct Subject
    include JSON::Serializable

    property title : String
    property type : String
  end

  struct Repository
    include JSON::Serializable

    property full_name : String
  end
end