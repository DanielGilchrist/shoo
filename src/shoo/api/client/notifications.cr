module Shoo
  module API
    class Client
      struct Notifications
        def initialize(@client : Client)
        end

        def list(per_page : UInt8) : API::Result(Array(Notification))
          @client.get(Array(Notification), "/notifications", query: {
            "per_page" => per_page.to_s,
          })
        end

        def mark_as_done(notification_id : String) : Bool
          @client.delete("/notifications/threads/#{notification_id}")
        end

        def unsubscribe(notification_id : String) : Bool
          @client.delete("/notifications/threads/#{notification_id}/subscription")
        end
      end
    end
  end
end
