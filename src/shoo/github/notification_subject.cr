module Shoo
  module GitHub
    struct NotificationSubject
      include JSON::Serializable

      getter title : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::SubjectType)]
      getter type : SubjectType

      getter url : String?

      def should_check_author? : Bool
        type.pull_request? || type.issue?
      end

      # The notifications API exposes the issue or pull request only as its API
      # url; the number is that url's last path segment.
      def number : Int32?
        url.try { |value| URI.parse(value).path.rpartition('/')[2].to_i? }
      end
    end
  end
end
