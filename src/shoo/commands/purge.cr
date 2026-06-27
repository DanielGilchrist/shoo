module Shoo
  module Commands
    @[Kebab::Command(summary: "Purge unwanted notifications")]
    struct Purge
      include Kebab::Parseable

      @[Kebab::Option(long: "dry-run", description: "Show what would be purged without actually purging")]
      getter? dry_run : Bool = false

      @[Kebab::Option(description: "Show detailed output")]
      getter? verbose : Bool = false

      @[Kebab::Option(description: "Skip purge check")]
      getter? force : Bool = false

      def run(context : Context) : Nil
        stdout = context.stdout
        client = context.client

        show_mode_banner(stdout)

        github_notifications =
          case result = client.notifications.all
          in Array(GitHub::Notification)
            result
          in GitHub::Error
            context.abort!("Error fetching notifications: #{result.message}")
          end

        results = NotificationFilter.new(context.config, client, github_notifications).filter

        keeping = Array(::Shoo::Notification::Kept).new
        removing = Array(::Shoo::Notification::Purged).new

        results.each do |notification|
          case notification
          in ::Shoo::Notification::Kept
            keeping << notification
          in ::Shoo::Notification::Purged
            removing << notification
          end
        end

        purge_count = removing.size

        if verbose?
          show_summary(stdout, github_notifications, results)
          stdout.puts
        else
          show_brief_summary(stdout, keeping, removing)
        end

        if purge_count.zero?
          return stdout.puts "No notifications to purge."
        end

        return perform_purge(context, removing) if force?

        if dry_run?
          show_dry_run_details(stdout, removing)
        elsif confirm_purge(context, purge_count)
          perform_purge(context, removing)
        else
          stdout.puts "Purge cancelled."
        end
      end

      private def show_mode_banner(io : IO) : Nil
        if dry_run?
          io.puts "🔍 #{"[DRY RUN MODE]".colorize.cyan.bold} Analyzing notifications to show what would be purged..."
        else
          io.puts "🧹 #{"[PURGE MODE]".colorize.red.bold} Fetching and purging notifications..."
        end
      end

      private def show_brief_summary(io : IO, keeping : Array(::Shoo::Notification::Kept), removing : Array(::Shoo::Notification::Purged)) : Nil
        io.puts "Keeping #{keeping.size.to_s.colorize.green.bold} notifications, removing #{removing.size.to_s.colorize.red.bold} notifications"
      end

      private def show_summary(io : IO, github_notifications : Array(GitHub::Notification), results : Array(::Shoo::Notification::Any)) : Nil
        io.puts "Total notifications: #{github_notifications.size}".colorize.white.bold
        Representers::NotificationVerdict.new(results).display(io)
      end

      private def show_dry_run_details(io : IO, removing : Array(::Shoo::Notification::Purged)) : Nil
        io.puts "\n🔍 #{"[DRY RUN]".colorize.cyan.bold} The following #{removing.size} notifications would be purged:"
        io.puts "=" * 80

        reason_width = Formatting.reason_width(removing)
        purge_reason_width = Formatting.purge_reason_width(removing)

        removing.each_with_index do |notification, index|
          show_notification_detail(io, notification, index + 1, reason_width, purge_reason_width)
        end

        # TODO: Make this dynamic based on window size (or just remove it)
        io.puts "=" * 80
        io.puts "#{"No changes will be made.".colorize.green} Remove `--dry-run` to actually purge."
      end

      private def confirm_purge(context : Context, count : Int32) : Bool
        context.stdout.puts "\n⚠️  You are about to purge #{count.to_s.colorize.red.bold} notifications."
        context.stdout.print "Are you sure? (y/N): "
        response = context.stdin.gets.try(&.strip.downcase)
        response == "y" || response == "yes"
      end

      private def perform_purge(context : Context, removing : Array(::Shoo::Notification::Purged)) : Nil
        config = context.config
        io = context.stdout

        io.puts "🧹 #{"Purging".colorize.red.bold} #{removing.size} notifications..."

        notifications_client = context.client.notifications
        results = ConcurrentWorker.run(removing) do |notification|
          rules = config.purge_rules_for(notification.repository_name)

          if rules.unsubscribe?
            notifications_client.unsubscribe(notification.id)
          end

          notifications_client.mark_as_done(notification.id)
        end

        success_count = results.count(true)
        error_count = results.count(false)

        io.puts "\n✅ Successfully purged #{success_count.to_s.colorize.green.bold} notifications"
        if error_count > 0
          io.puts "❌ Failed to purge #{error_count.to_s.colorize.red.bold} notifications"
        end
      end

      private def show_notification_detail(io : IO, notification : ::Shoo::Notification::Purged, number : Int32, reason_width : Int32, purge_reason_width : Int32) : Nil
        reason = Formatting.colourised_reason(notification.reason, reason_width)
        tag = Formatting.colourised_purge_reason(notification.purge_reason, purge_reason_width)

        io.puts "#{number.to_s.colorize.white.bold}. [#{reason}] #{tag} | #{notification.subject.title}"
        io.puts "   #{"Repository:".colorize.light_gray} #{notification.repository.full_name.colorize.light_cyan}"
        io.puts "   #{"ID:".colorize.light_gray} #{notification.id.colorize.light_gray}"
        io.puts ""
      end
    end
  end
end
