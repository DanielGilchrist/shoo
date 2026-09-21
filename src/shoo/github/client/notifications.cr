module Shoo
  module GitHub
    struct Client
      struct Notifications
        def initialize(@request : Request) : Nil
        end

        PATH = "/notifications"

        def all(per_page : Int32 = 50) : Array(Notification) | Error
          all(per_page) { }
        end

        def all(per_page : Int32 = 50, & : Array(Notification) ->) : Array(Notification) | Error
          first =
            case page = list(1, per_page)
            in Error              then return page
            in Page(Notification) then page
            end

          yield first.items

          notifications = first.items.dup
          remaining = (2..(first.last_page || 1)).to_a

          Future.all(remaining) { |number| list(number, per_page) }.each do |fetched|
            case fetched
            in Error
              return fetched
            in Page(Notification)
              yield fetched.items
              notifications.concat(fetched.items)
            end
          end

          notifications
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28&versionId=free-pro-team%40latest&productId=rest#list-notifications-for-the-authenticated-user
        def list(page : Int32 = 1, per_page : Int32 = 50) : Page(Notification) | Error
          query = {"page" => page.to_s, "per_page" => per_page.to_s}

          case fetched = @request.get(Array(Notification), PATH, query: query)
          in Error then fetched
          in Fetched(Array(Notification))
            Page(Notification).new(fetched.value, LinkHeader.last_page(fetched.headers))
          end
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28&versionId=free-pro-team%40latest&productId=rest#mark-notifications-as-read
        def mark_as_done(notification_id : String) : Error?
          @request.delete("/notifications/threads/#{notification_id}")
        end

        # https://docs.github.com/en/rest/activity/notifications?apiVersion=2022-11-28#delete-a-thread-subscription
        def unsubscribe(notification_id : String) : Error?
          @request.delete("/notifications/threads/#{notification_id}/subscription")
        end
      end
    end
  end
end
