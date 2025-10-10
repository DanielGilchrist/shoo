module Shoo
  module Commands
    struct Purge < Command
      def execute : Nil
        show_mode_banner

        token = retrieve_token!
        client = API::Client.new(token)

        notifications = fetch_notifications(client)
        notification_filter = NotificationFilter.new(@config, client)
        notifications_to_keep, notifications_to_purge = notification_filter.filter(notifications)

        if @verbose
          show_summary(notifications, notifications_to_keep, notifications_to_purge)
        else
          show_brief_summary(notifications_to_keep, notifications_to_purge)
        end

        if @dry_run
          show_dry_run_details(notifications_to_purge)
        else
          purge_count = notifications_to_purge.size

          if purge_count.zero?
            puts "No notifications to purge."
          elsif confirm_purge(purge_count)
            perform_purge(notifications_to_purge, client)
          else
            puts "Purge cancelled."
          end
        end
      end

      private def show_mode_banner : Nil
        if @dry_run
          puts "🔍 #{"[DRY RUN MODE]".colorize.cyan.bold} Analyzing notifications to show what would be purged..."
        else
          puts "🧹 #{"[PURGE MODE]".colorize.red.bold} Fetching and purging notifications..."
        end
        puts ""
      end

      private def show_brief_summary(keeping : Array(API::Notification), removing : Array(API::Notification)) : Nil
        puts "Keeping #{keeping.size.to_s.colorize.green.bold} notifications, removing #{removing.size.to_s.colorize.red.bold} notifications"
      end

      private def show_summary(notifications : Array(API::Notification), keeping : Array(API::Notification), removing : Array(API::Notification)) : Nil
        puts "Total notifications: #{notifications.size}".colorize.white.bold

        show_keeping_list(keeping)
        show_removing_list(removing)
      end

      private def show_dry_run_details(notifications_to_purge : Array(API::Notification)) : Nil
        puts "\n🔍 #{"[DRY RUN]".colorize.cyan.bold} The following #{notifications_to_purge.size} notifications would be purged:"
        puts "=" * 80

        notifications_to_purge.each_with_index do |notification, index|
          show_notification_detail(notification, index + 1)
        end

        # TODO: Make this dynamic based on window size (or just remove it)
        puts "=" * 80
        puts "#{"No changes will be made.".colorize.green} Remove `--dry-run` to actually purge."
      end

      private def confirm_purge(count : Int32) : Bool
        puts "\n⚠️  You are about to purge #{count.to_s.colorize.red.bold} notifications."
        print "Are you sure? (y/N): "
        response = gets.try(&.strip.downcase)
        response == "y" || response == "yes"
      end

      private def perform_purge(notifications_to_purge : Array(API::Notification), client : API::Client) : Nil
        puts "\n🧹 #{"Purging".colorize.red.bold} #{notifications_to_purge.size} notifications..."

        notifications = client.notifications
        results = ConcurrentWorker.run(notifications_to_purge) do |notification|
          rules = @config.rules_for(notification)

          if rules.unsubscribe?
            notifications.unsubscribe(notification.id)
          end

          notifications.mark_as_done(notification.id)
        end

        success_count = results.count(true)
        error_count = results.count(false)

        puts "\n✅ Successfully purged #{success_count.to_s.colorize.green.bold} notifications"
        if error_count > 0
          puts "❌ Failed to purge #{error_count.to_s.colorize.red.bold} notifications"
        end
      end

      private def fetch_notifications(client : API::Client) : Array(API::Notification)
        # TODO: Handle pagination properly
        client.notifications.list(per_page: 100).or do |error|
          puts "Error fetching notifications: #{error.message}"
          exit 1
        end
      end

      private def show_keeping_list(notifications : Array(API::Notification)) : Nil
        puts "\n--- KEEPING (#{notifications.size}) ---".colorize.green.bold
        notifications.each do |notification|
          puts "#{notification.reason.colorize.blue} | #{notification.subject.title}"
        end
      end

      private def show_removing_list(notifications : Array(API::Notification)) : Nil
        puts "\n--- REMOVING (#{notifications.size}) ---".colorize.red.bold
        notifications.each do |notification|
          puts "#{colourised_reason(notification.reason)} | #{notification.subject.title}"
        end
      end

      private def show_notification_detail(notification : API::Notification, number : Int32) : Nil
        puts "#{number.to_s.colorize.white.bold}. [#{colourised_reason(notification.reason)}] #{notification.subject.title}"
        puts "   #{"Repository:".colorize.light_gray} #{notification.repository.full_name.colorize.light_cyan}"
        puts "   #{"ID:".colorize.light_gray} #{notification.id.colorize.light_gray}"
        puts ""
      end

      private def colourised_reason(reason : API::NotificationReason)
        case reason
        when .ci_activity?
          reason.to_s.colorize.yellow
        when .review_requested?
          reason.to_s.colorize.magenta
        when .mention?
          reason.to_s.colorize.green
        when .comment?
          reason.to_s.colorize.blue
        else
          reason.to_s.colorize.white
        end
      end
    end
  end
end
