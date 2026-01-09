module Shoo
  module GitHub
    struct Notification
      include JSON::Serializable

      getter id : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::NotificationReason)]
      getter reason : NotificationReason

      getter subject : Subject
      getter repository : Repository

      def authored? : Bool
        reason.author?
      end

      def subscribed? : Bool
        reason.subscribed?
      end

      def manually_subscribed? : Bool
        reason.manual?
      end

      def commented? : Bool
        reason.comment?
      end

      def assigned? : Bool
        reason.assign?
      end

      def team_mentioned? : Bool
        reason.team_mention?
      end

      def always_keep? : Bool
        authored? || subscribed? || commented? || assigned? || manually_subscribed?
      end

      def repository_name : String
        repository.full_name
      end
    end
  end
end
