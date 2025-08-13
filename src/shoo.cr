require "option_parser"
require "colorize"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  def main(args : Array(String))
    options = parse_options!(args)

    if command = options.command
      execute_command!(command, options.dry_run, options.verbose)
    else
      puts "#{"Invalid command: ".colorize.red}\"#{args.join(" ").colorize.bold}\""
      help(options.parser)
    end
  end

  def parse_options!(args : Array(String)) : Options
    options = Options.new

    options.parser = OptionParser.parse(args) do |parser|
      parser.banner = "Usage: shoo [subcommand] [arguments]"

      parser.on("notification", "Commands for notifications") do
        parser.on("purge", "Purge unwanted notifications") do
          options.command = Commands::Purge
        end

        parser.on("--dry-run", "Show what would be purged without actually purging") do
          options.dry_run = true
        end

        parser.on("--verbose", "Show detailed output") do
          options.verbose = true
        end

        define_help(parser)
      end

      parser.invalid_option do |option|
        print_and_exit!("Invalid option '#{option}'") do
          help(parser)
        end
      end

      define_help(parser)
    end

    options
  rescue e : OptionParser::InvalidOption
    print_and_exit!(e.message || "Something went wrong")
  end

  private def print_and_exit!(message : String, &) : NoReturn
    puts message
    yield
    exit(0)
  end

  private def print_and_exit!(message : String) : NoReturn
    print_and_exit!(message) { }
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

  private struct Options
    class MissingParser < Exception
      def initialize
        super("parser should not be `nil`!")
      end
    end

    def initialize(
      @dry_run = false,
      @verbose = false,
      @command : (Commands::Command.class)? = nil,
      @parser : OptionParser? = nil
    )
    end

    property dry_run : Bool
    property verbose : Bool
    property command : (Commands::Command.class)?

    setter parser : OptionParser?

    def parser : OptionParser
      @parser || raise(MissingParser.new)
    end
  end
end

{% unless flag?(:test) %}
  {% if flag?(:debug) %}
    Shoo::Debug.setup
  {% end %}

  Shoo.main(args: ARGV)
{% end %}
