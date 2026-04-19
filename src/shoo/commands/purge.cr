module Shoo
  module Commands
    struct Purge < Command
      def execute : Nil
        show_mode_banner

        token = retrieve_token!
        client = GitHub::Client.new(token)

        github_notifications = fetch_notifications(client)
        notification_filter = NotificationFilter.new(@config, client, github_notifications)
        results = notification_filter.filter

        keeping = Array(Notification::Kept).new
        removing = Array(Notification::Purged).new

        results.each do |notification|
          case notification
          in Notification::Kept
            keeping << notification
          in Notification::Purged
            removing << notification
          end
        end

        purge_count = removing.size

        if @verbose
          show_summary(github_notifications, keeping, removing)
          puts
        else
          show_brief_summary(keeping, removing)
        end

        if purge_count.zero?
          return puts "No notifications to purge."
        end

        return perform_purge(removing, client) if @force

        if @dry_run
          show_dry_run_details(removing)
        else
          if purge_count.zero?
            puts "No notifications to purge."
          elsif confirm_purge(purge_count)
            perform_purge(removing, client)
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
      end

      private def show_brief_summary(keeping : Array(Notification::Kept), removing : Array(Notification::Purged)) : Nil
        puts "Keeping #{keeping.size.to_s.colorize.green.bold} notifications, removing #{removing.size.to_s.colorize.red.bold} notifications"
      end

      private def show_summary(github_notifications : Array(GitHub::Notification), keeping : Array(Notification::Kept), removing : Array(Notification::Purged)) : Nil
        puts "Total notifications: #{github_notifications.size}".colorize.white.bold

        show_keeping_list(keeping)
        show_removing_list(removing)
      end

      private def show_dry_run_details(removing : Array(Notification::Purged)) : Nil
        puts "\n🔍 #{"[DRY RUN]".colorize.cyan.bold} The following #{removing.size} notifications would be purged:"
        puts "=" * 80

        reason_width = max_reason_width(removing)
        purge_reason_width = max_purge_reason_width(removing)

        removing.each_with_index do |notification, index|
          show_notification_detail(notification, index + 1, reason_width, purge_reason_width)
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

      private def perform_purge(removing : Array(Notification::Purged), client : GitHub::Client) : Nil
        puts "🧹 #{"Purging".colorize.red.bold} #{removing.size} notifications..."

        notifications_client = client.notifications
        results = ConcurrentWorker.run(removing) do |notification|
          rules = @config.purge_rules_for(notification.repository_name)

          if rules.unsubscribe?
            notifications_client.unsubscribe(notification.id)
          end

          notifications_client.mark_as_done(notification.id)
        end

        success_count = results.count(true)
        error_count = results.count(false)

        puts "\n✅ Successfully purged #{success_count.to_s.colorize.green.bold} notifications"
        if error_count > 0
          puts "❌ Failed to purge #{error_count.to_s.colorize.red.bold} notifications"
        end
      end

      private def fetch_notifications(client : GitHub::Client) : Array(GitHub::Notification)
        Paginator.paginate do |page, per_page|
          client.notifications.list(page, per_page).expect!("Error fetching notifications")
        end
      end

      private def show_keeping_list(notifications : Array(Notification::Kept)) : Nil
        puts "\n--- KEEPING (#{notifications.size}) ---".colorize.green.bold

        reason_width = max_reason_width(notifications)

        notifications.each do |notification|
          puts "#{colourised_reason(notification.reason, reason_width)} | #{notification.subject.title}"
        end
      end

      private def show_removing_list(notifications : Array(Notification::Purged)) : Nil
        puts "\n--- REMOVING (#{notifications.size}) ---".colorize.red.bold

        reason_width = max_reason_width(notifications)
        purge_reason_width = max_purge_reason_width(notifications)

        notifications.each do |notification|
          reason = colourised_reason(notification.reason, reason_width)
          tag = colourised_purge_reason(notification.purge_reason, purge_reason_width)

          puts "#{reason} | #{tag} | #{notification.subject.title}"
        end
      end

      private def show_notification_detail(notification : Notification::Purged, number : Int32, reason_width : Int32, purge_reason_width : Int32) : Nil
        reason = colourised_reason(notification.reason, reason_width)
        tag = colourised_purge_reason(notification.purge_reason, purge_reason_width)

        puts "#{number.to_s.colorize.white.bold}. [#{reason}] #{tag} | #{notification.subject.title}"
        puts "   #{"Repository:".colorize.light_gray} #{notification.repository.full_name.colorize.light_cyan}"
        puts "   #{"ID:".colorize.light_gray} #{notification.id.colorize.light_gray}"
        puts ""
      end

      private def max_reason_width(notifications : Array) : Int32
        notifications.max_of?(&.reason.to_s.size) || 0
      end

      private def max_purge_reason_width(notifications : Array(Notification::Purged)) : Int32
        notifications.max_of?(&.purge_reason.to_s.size) || 0
      end

      private def colourised_purge_reason(reason : PurgeReason, width : Int32) : String
        padded = reason.to_s.ljust(width)

        case reason
        in .merged?
          padded.colorize.light_magenta.to_s
        in .closed?
          padded.colorize.red.to_s
        in .filtered?
          padded.colorize.dark_gray.to_s
        end
      end

      private def colourised_reason(reason : GitHub::NotificationReason, width : Int32)
        padded = reason.to_s.ljust(width)

        case reason
        when .ci_activity?
          padded.colorize.yellow
        when .review_requested?
          padded.colorize.magenta
        when .mention?
          padded.colorize.green
        when .comment?
          padded.colorize.blue
        else
          padded.colorize.white
        end
      end
    end
  end
end
