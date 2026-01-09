module Shoo
  module GitHub
    struct Subject
      include JSON::Serializable

      getter title : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::SubjectType)]
      getter type : SubjectType

      getter url : String?

      def should_check_author? : Bool
        type.pull_request? || type.issue?
      end
    end
  end
end
