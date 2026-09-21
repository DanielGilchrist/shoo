module Shoo
  module Commands
    @[Kebab::Command(summary: "List notifications without purging")]
    struct List
      include Kebab::Parseable

      @[Kebab::Option(long: "verdict", description: "Show whether each notification would be kept or purged")]
      getter? verdict : Bool = false

      @[Kebab::Option(long: "repo", description: "Only show notifications for this repository (owner/name)")]
      getter repo : String?

      @[Kebab::Option(long: "org", description: "Only show notifications for this organisation (owner)")]
      getter org : String?

      @[Kebab::Option(long: "reason", description: "Only show notifications with this reason", converter: Kebab::Convert::Enum(GitHub::NotificationReason))]
      getter reason : GitHub::NotificationReason?

      @[Kebab::Option(long: "search", description: "Only show notifications whose title contains this text")]
      getter search : String?

      def run(context : Context) : Nil
        client = context.client
        stdout = context.stdout

        filter = NotificationFilter.new(context.config, client)
        status = context.status
        status.update("Fetching notifications")
        fetched_count = 0

        fetched = client.notifications.all do |page|
          fetched_count += page.size
          status.update("Fetched #{fetched_count} notifications")
          filter.add(apply_filters(page)) if verdict?
        end

        notifications =
          case fetched
          in Array(GitHub::Notification) then fetched
          in GitHub::Error
            context.abort!("Error fetching notifications: #{fetched.message}")
          end

        filtered = apply_filters(notifications)

        if filtered.empty?
          status.clear
          message = notifications.empty? ? "No notifications." : "No notifications match the given filters."
          return stdout.puts message
        end

        if verdict?
          status.update("Evaluating #{filtered.size} notifications")
          results =
            case evaluated = filter.filter
            in Array(::Shoo::Notification::Any) then evaluated
            in GitHub::Failure
              context.abort!("Error evaluating notifications: #{GitHub.describe(evaluated)}")
            end

          status.finish(summary(notifications.size, client.request_count))
          Representers::NotificationVerdict.new(results).display(stdout)
        else
          status.finish(summary(notifications.size, client.request_count))
          Representers::NotificationList.new(filtered).display(stdout)
        end
      end

      private def summary(notification_count : Int32, request_count : Int32) : String
        "#{notification_count} notifications, #{request_count} requests"
      end

      private def apply_filters(notifications : Array(GitHub::Notification)) : Array(GitHub::Notification)
        notifications = filter_by_repo(notifications)
        notifications = filter_by_org(notifications)
        notifications = filter_by_reason(notifications)
        filter_by_search(notifications)
      end

      private def filter_by_repo(notifications : Array(GitHub::Notification)) : Array(GitHub::Notification)
        repo = self.repo
        return notifications unless repo

        notifications.select(&.repository.full_name.==(repo))
      end

      private def filter_by_org(notifications : Array(GitHub::Notification)) : Array(GitHub::Notification)
        org = self.org
        return notifications unless org

        notifications.select(&.repository.organisation_name.==(org))
      end

      private def filter_by_reason(notifications : Array(GitHub::Notification)) : Array(GitHub::Notification)
        reason = self.reason
        return notifications unless reason

        notifications.select(&.reason.==(reason))
      end

      private def filter_by_search(notifications : Array(GitHub::Notification)) : Array(GitHub::Notification)
        search = self.search
        return notifications unless search

        query = search.downcase
        notifications.select(&.subject.title.downcase.includes?(query))
      end
    end
  end
end
