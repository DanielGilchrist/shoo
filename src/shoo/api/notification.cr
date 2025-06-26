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
      StateChange
      TeamMention
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

      getter id : String

      @[JSON::Field(converter: Shoo::API::Notification::NotificationReasonConverter)]
      getter reason : NotificationReason

      getter subject : Subject
      getter repository : Repository

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

      getter title : String

      @[JSON::Field(converter: Shoo::API::Subject::SubjectTypeConverter)]
      getter type : SubjectType

      getter url : String?

      def should_check_author? : Bool
        type.pull_request? || type.issue?
      end
    end

    struct Repository
      include JSON::Serializable

      getter full_name : String
    end
  end
end
