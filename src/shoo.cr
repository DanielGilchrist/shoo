require "option_parser"
require "colorize"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  def main(args : Array(String))
    command : (Commands::Command.class)? = nil
    dry_run = false
    verbose = false

    OptionParser.parse(args) do |parser|
      parser.banner = "Usage: shoo [subcommand] [arguments]"

      parser.on("notification", "Commands for notifications") do
        parser.on("purge", "Purge unwanted notifications") do
          command = Commands::Purge
        end

        parser.on("--dry-run", "Show what would be purged without actually purging") do
          dry_run = true
        end

        parser.on("--verbose", "Show detailed output") do
          verbose = true
        end

        define_help(parser)
      end

      define_help(parser)
    end.tap do |parser|
      if cmd = command
        execute_command!(cmd, dry_run, verbose)
      else
        puts "#{"Invalid command: ".colorize.red}\"#{args.join(" ").colorize.bold}\""
        help(parser)
      end
    end
  end

  # TODO: Make this more generic
  private def execute_command!(command : Commands::Command.class, dry_run : Bool = false, verbose : Bool = false)
    config = Config.load
    command.new(config, dry_run, verbose).execute
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

{% unless flag?(:test) %}
  {% if flag?(:debug) %}
    Shoo::Debug.setup
  {% end %}

  Shoo.main(args: ARGV)
{% end %}
