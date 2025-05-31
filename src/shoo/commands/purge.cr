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

        filter = NotificationFilter.new(@config, client)
        notifications_to_keep = notifications.select { |n| filter.should_keep?(n) }
        notifications_to_purge = notifications.reject { |n| filter.should_keep?(n) }

        puts "Total notifications: #{notifications.size}"
        puts "Keeping: #{notifications_to_keep.size}"
        puts "Purging: #{notifications_to_purge.size}"

        puts "\n--- KEEPING ---"
        notifications_to_keep.each do |n|
          puts "#{n.reason} | #{n.subject.title}"
        end

        pp!(notifications_to_keep[0])
      end
    end
  end
end
