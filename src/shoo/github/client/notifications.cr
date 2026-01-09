module Shoo
  module GitHub
    struct Client
      struct Notifications
        def initialize(@request : Request)
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28&versionId=free-pro-team%40latest&productId=rest#list-notifications-for-the-authenticated-user
        def list(page : Int32 = 1, per_page : Int32 = 50) : Result(Array(Notification))
          @request.get(Array(Notification), "/notifications", query: {
            "page"     => page.to_s,
            "per_page" => per_page.to_s,
          })
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28&versionId=free-pro-team%40latest&productId=rest#mark-notifications-as-read
        def mark_as_done(notification_id : String) : Bool
          @request.delete("/notifications/threads/#{notification_id}")
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28#delete-a-thread-subscription
        def unsubscribe(notification_id : String) : Bool
          @request.delete("/notifications/threads/#{notification_id}/subscription")
        end
      end
    end
  end
end
