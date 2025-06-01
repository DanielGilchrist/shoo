module Shoo
  module API
    struct Notifications
      def initialize(@client : Client)
      end

      def list : API::Result(Array(Notification))
        @client.get(Array(Notification), "/notifications")
      end

      def mark_as_done(notification_id : String) : Bool
        @client.delete("/notifications/threads/#{notification_id}")
      end
    end
  end
end
