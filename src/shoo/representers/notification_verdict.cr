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
        return if keeping.empty?

        width = column_width(keeping.map(&.keep_reason.label), "Why kept")
        io.puts header("Why kept", width)

        keeping.each do |notification|
          io.puts "#{notification.keep_reason.colourise(width)} | #{notification.subject.title}"
        end
      end

      private def display_removing(io : IO, removing : Array(Notification::Purged)) : Nil
        io.puts "\n--- REMOVING (#{removing.size}) ---".colorize.red.bold
        return if removing.empty?

        width = column_width(removing.map { |notification| purge_label(notification) }, "Why purged")
        io.puts header("Why purged", width)

        removing.each do |notification|
          tag = notification.purge_reason.paint(purge_label(notification).ljust(width))
          io.puts "#{tag} | #{notification.subject.title}"
        end
      end

      private def purge_label(notification : Notification::Purged) : String
        purge_reason = notification.purge_reason
        return purge_reason.label unless purge_reason.filtered?

        "#{notification.reason.description} → #{purge_reason.label}"
      end

      private def column_width(labels : Array(String), header : String) : Int32
        ([header.size] + labels.map(&.size)).max
      end

      private def header(label : String, width : Int32) : String
        row = "#{label.ljust(width)} | Title"
        "#{row.colorize.bold}\n#{("─" * row.size).colorize.dark_gray}"
      end
    end
  end
end
