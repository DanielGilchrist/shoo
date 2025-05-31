module Shoo
  module Commands
    struct Purge < Command
      def execute
        token = retrieve_token!
        client = API::Client.new(token)

        notifications = client.notifications.list.or do |error|
          puts "Error fetching notifications: #{error.message}"
          exit 1
        end

        notification_filter = NotificationFilter.new(@config, client)
        notifications_to_keep, notifications_to_purge = notification_filter.filter(notifications)

        puts "Total notifications: #{notifications.size}"

        puts "\n--- KEEPING (#{notifications_to_keep.size}) ---"
        notifications_to_keep.each do |n|
          puts "#{n.reason} | #{n.subject.title}"
        end

        puts "\n--- REMOVING (#{notifications_to_purge.size}) ---"
        notifications_to_purge.each do |n|
          puts "#{n.reason} | #{n.subject.title}"
        end

        pp!(notifications_to_keep[0..10])
        puts
        pp!(notifications_to_purge.reject(&.reason.==("ci_activity"))[0..10])
      end
    end
  end
end
