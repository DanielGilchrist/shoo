require "log"

module Shoo
  module Debug
    def self.setup : Nil
      Log.setup(:debug, Backend.new)
    end

    class Backend < Log::IOBackend
      def write(entry : Log::Entry) : Nil
        puts "\n"
        pp "================================= DEBUG ================================="
        puts entry.message.colorize.yellow
        puts "\n"
        entry.data.each do |(k, v)|
          next if v.raw.nil?

          key = "#{k}: "
          print "#{key.colorize.light_yellow}"
          puts v
          puts "\n" unless http_debug_message?(entry)
        end
        pp "================================= DEBUG ================================="
        puts "\n"
      end

      private def http_debug_message?(entry : Log::Entry) : Bool
        entry.message == "Performing request"
      end
    end
  end
end
