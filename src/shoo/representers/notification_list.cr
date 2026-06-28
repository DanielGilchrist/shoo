module Shoo
  module Representers
    struct NotificationList
      def initialize(@notifications : Array(GitHub::Notification))
      end

      def display(io : IO) : Nil
        groups = @notifications
          .group_by(&.repository.full_name)
          .to_a
          .sort_by { |name, notifications| {-notifications.size, name} }

        io.puts summary(@notifications.size, groups.size)

        reason_width = @notifications.max_of?(&.reason.to_s.size) || 0

        groups.each do |repository_name, notifications|
          io.puts
          io.puts "#{repository_name.colorize.cyan.bold} #{"(#{notifications.size})".colorize.dark_gray}"

          notifications
            .sort_by { |notification| {notification.reason.to_s, notification.subject.title} }
            .each do |notification|
              reason = notification.reason.colourise(reason_width)
              io.puts "  #{reason}  #{notification.subject.title}"
            end
        end
      end

      private def summary(notification_count : Int32, repository_count : Int32) : String
        notifications = notification_count == 1 ? "notification" : "notifications"
        repositories = repository_count == 1 ? "repository" : "repositories"

        "#{notification_count} #{notifications} across #{repository_count} #{repositories}".colorize.white.bold.to_s
      end
    end
  end
end
