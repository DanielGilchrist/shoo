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

        notifications = client.notifications.all.unwrap_or do |error|
          context.abort!("Error fetching notifications: #{error.message}")
        end

        filtered = apply_filters(notifications)

        if filtered.empty?
          message = notifications.empty? ? "No notifications." : "No notifications match the given filters."
          return stdout.puts message
        end

        if verdict?
          results = NotificationFilter.new(context.config, client, filtered).filter.unwrap_or do |error|
            context.abort!("Error evaluating notifications: #{error.message}")
          end

          Representers::NotificationVerdict.new(results).display(stdout)
        else
          Representers::NotificationList.new(filtered).display(stdout)
        end
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
