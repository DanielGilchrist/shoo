module Shoo
  module Representers
    struct NotificationVerdict
      def initialize(@results : Array(Notification::Any))
      end

      def display(io : IO) : Nil
        keeping = [] of Notification::Kept
        removing = [] of Notification::Purged

        @results.each do |result|
          case result
          in Notification::Kept
            keeping << result
          in Notification::Purged
            removing << result
          end
        end

        display_keeping(io, keeping)
        display_removing(io, removing)
      end

      private def display_keeping(io : IO, keeping : Array(Notification::Kept)) : Nil
        io.puts "\n--- KEEPING (#{keeping.size}) ---".colorize.green.bold

        width = Formatting.reason_width(keeping)

        keeping.each do |notification|
          reason = Formatting.colourised_reason(notification.reason, width)
          io.puts "#{reason} | #{notification.subject.title}"
        end
      end

      private def display_removing(io : IO, removing : Array(Notification::Purged)) : Nil
        io.puts "\n--- REMOVING (#{removing.size}) ---".colorize.red.bold

        reason_width = Formatting.reason_width(removing)
        purge_reason_width = Formatting.purge_reason_width(removing)

        removing.each do |notification|
          reason = Formatting.colourised_reason(notification.reason, reason_width)
          tag = Formatting.colourised_purge_reason(notification.purge_reason, purge_reason_width)
          io.puts "#{reason} | #{tag} | #{notification.subject.title}"
        end
      end
    end
  end
end
