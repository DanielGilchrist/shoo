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

        filter = NotificationFilter.new(context.config, client)
        status = context.status
        status.update("Fetching notifications")
        fetched_count = 0

        github_notifications =
          case fetched = client.notifications.all { |page|
            fetched_count += page.size
            status.update("Fetched #{fetched_count} notifications")
            filter.add(page)
          }
          in Array(GitHub::Notification) then fetched
          in GitHub::Error
            context.abort!("Error fetching notifications: #{fetched.message}")
          end

        status.update("Evaluating #{github_notifications.size} notifications")

        results =
          case evaluated = filter.filter
          in Array(::Shoo::Notification::Any) then evaluated
          in GitHub::Failure
            context.abort!("Error evaluating notifications: #{GitHub.describe(evaluated)}")
          end

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
        status.finish("#{github_notifications.size} notifications, #{client.request_count} requests")

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
          io.puts "#{"[DRY RUN MODE]".colorize.cyan.bold} Analyzing notifications to show what would be purged..."
        else
          io.puts "#{"[PURGE MODE]".colorize.red.bold} Fetching and purging notifications..."
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
        io.puts "\n#{"[DRY RUN]".colorize.cyan.bold} The following #{removing.size} notifications would be purged:"
        io.puts "=" * 80

        reason_width = removing.max_of?(&.reason.to_s.size) || 0
        purge_reason_width = removing.max_of?(&.purge_reason.label.size) || 0

        removing.each_with_index do |notification, index|
          show_notification_detail(io, notification, index + 1, reason_width, purge_reason_width)
        end

        # TODO: Make this dynamic based on window size (or just remove it)
        io.puts "=" * 80
        io.puts "#{"No changes will be made.".colorize.green} Remove `--dry-run` to actually purge."
      end

      private def confirm_purge(context : Context, count : Int32) : Bool
        context.stdout.puts "\nYou are about to purge #{count.to_s.colorize.red.bold} notifications."
        context.stdout.print "Are you sure? (y/N): "
        response = context.stdin.gets.try(&.strip.downcase)
        response == "y" || response == "yes"
      end

      private def perform_purge(context : Context, removing : Array(::Shoo::Notification::Purged)) : Nil
        config = context.config
        io = context.stdout

        io.puts "#{"Purging".colorize.red.bold} #{removing.size} notifications..."

        status = context.status
        notifications_client = context.client.notifications
        attempted = 0

        failures = Future.all(removing) do |notification|
          error = purge_notification(notifications_client, config, notification)
          attempted += 1
          status.update("Purged #{attempted}/#{removing.size}")
          {notification, error} if error
        end.compact

        status.finish("#{removing.size - failures.size} purged, #{context.client.request_count} requests")

        purged_count = removing.size - failures.size
        io.puts "\nPurged #{purged_count.to_s.colorize.green.bold} notifications"

        unless failures.empty?
          io.puts "Failed to purge #{failures.size.to_s.colorize.red.bold} notifications:"
          failures.each do |notification, error|
            io.puts "   #{notification.subject.title.colorize.light_gray}: #{error.message}"
          end
        end
      end

      private def purge_notification(client : GitHub::Client::Notifications, config : ::Shoo::Config, notification : ::Shoo::Notification::Purged) : GitHub::Error?
        rules = config.purge_rules_for(notification.repository_name)

        if rules.unsubscribe?
          error = client.unsubscribe(notification.id)
          return error if error
        end

        client.mark_as_done(notification.id)
      end

      private def show_notification_detail(io : IO, notification : ::Shoo::Notification::Purged, number : Int32, reason_width : Int32, purge_reason_width : Int32) : Nil
        reason = notification.reason.colourise(reason_width)
        tag = notification.purge_reason.colourise(purge_reason_width)

        io.puts "#{number.to_s.colorize.white.bold}. [#{reason}] #{tag} | #{notification.subject.title}"
        io.puts "   #{"Repository:".colorize.light_gray} #{notification.repository.full_name.colorize.light_cyan}"
        io.puts "   #{"ID:".colorize.light_gray} #{notification.id.colorize.light_gray}"
        io.puts ""
      end
    end
  end
end
