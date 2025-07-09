module Shoo
  module API
    struct Subject
      include JSON::Serializable

      getter title : String

      @[JSON::Field(converter: Shoo::API::Converters::SubjectType)]
      getter type : SubjectType

      getter url : String?

      def should_check_author? : Bool
        type.pull_request? || type.issue?
      end
    end
  end
end
