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

      def authored? : Bool
        reason.author?
      end

      def subscribed? : Bool
        reason.subscribed?
      end

      def always_keep? : Bool
        authored? || subscribed?
      end
    end
  end
end
