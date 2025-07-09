require "json"

module Shoo
  module API
    struct Notification
      include JSON::Serializable

      getter id : String

      @[JSON::Field(converter: Shoo::API::Converters::NotificationReason)]
      getter reason : NotificationReason

      getter subject : Subject
      getter repository : Repository

      def authored?
        reason.author?
      end
    end
  end
end
