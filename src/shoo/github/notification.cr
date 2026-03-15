module Shoo
  module GitHub
    struct Notification
      include JSON::Serializable

      getter id : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::NotificationReason)]
      getter reason : NotificationReason

      getter subject : Subject
      getter repository : Repository
    end
  end
end
