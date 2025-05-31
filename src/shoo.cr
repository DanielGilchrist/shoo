require "option_parser"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  def main
    OptionParser.new do |parser|
      parser.banner = "Usage: shoo [subcommand] [arguments]"

      parser.on("notification", "Commands for notifications") do
        parser.on("purge", "Purge unwanted notifications") do
          config = Config.load
          token = retrieve_token!(config)

          client = API::Client.new(token)
          notifications = client.notifications.list.or do |error|
            puts "Error fetching notifications: #{error.message}"
            exit 1
          end

          filter = NotificationFilter.new(config, client)
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

        define_help(parser)
      end

      define_help(parser)
    end.parse
  end

  private def define_help(parser : OptionParser)
    parser.on("help", "Show this help") { help(parser) }
    parser.on("-h", "--help", "Show this help") { help(parser) }
  end

  private def help(parser : OptionParser)
    puts parser
    exit
  end

  private def retrieve_token!(config : Config)
    token = config.github.github_token

    if token.nil? || token.blank?
      puts "GitHub token not provided!"
      exit
    end

    token
  end
end

Shoo.main
