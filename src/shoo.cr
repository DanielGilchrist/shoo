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
          pp!(config)
          puts "PURGED"
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
end

Shoo.main
