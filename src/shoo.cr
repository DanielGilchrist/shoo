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
          result = client.notifications.list
          pp!(result)
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
