require "json"

module Shoo
  module API
    enum SubjectType
      CheckSuite
      Issue
      PullRequest
    end

    enum NotificationReason
      Author
      CiActivity
      Comment
      Mention
      ReviewRequested
    end

    struct Notification
      include JSON::Serializable

      module NotificationReasonConverter
        def self.from_json(value : JSON::PullParser) : NotificationReason
          NotificationReason.parse(value.read_string)
        end

        def self.to_json(value : NotificationReason, json : JSON::Builder)
          json.string(value.to_s)
        end
      end

      property id : String

      @[JSON::Field(converter: Shoo::API::Notification::NotificationReasonConverter)]
      property reason : NotificationReason

      property subject : Subject
      property repository : Repository

      def authored?
        reason.author?
      end
    end

    struct Subject
      include JSON::Serializable

      module SubjectTypeConverter
        def self.from_json(value : JSON::PullParser) : SubjectType
          SubjectType.parse(value.read_string)
        end

        def self.to_json(value : SubjectType, json : JSON::Builder)
          json.string(value.to_s)
        end
      end

      property title : String

      @[JSON::Field(converter: Shoo::API::Subject::SubjectTypeConverter)]
      property type : SubjectType

      property url : String?

      def should_check_author? : Bool
        type.pull_request? || type.issue?
      end
    end

    struct Repository
      include JSON::Serializable

      property full_name : String
    end
  end
end
