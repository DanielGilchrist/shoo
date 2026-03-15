module Shoo
  module Notification
    alias Any = Kept | Purged

    module Base
      delegate :id, :reason, :subject, :repository, to: @github_notification

      def repository_name : String
        repository.full_name
      end
    end

    struct Kept
      include Base

      def initialize(@github_notification : GitHub::Notification)
      end
    end

    struct Purged
      include Base

      getter purge_reason : PurgeReason

      def initialize(@github_notification : GitHub::Notification, @purge_reason : PurgeReason)
      end
    end
  end
end
