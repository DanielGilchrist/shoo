module Shoo
  struct Parser
    class Error < RuntimeError
    end

    def initialize(@args : Array(String))
      @options = Options.new(args)
    end

    def parse! : Options
      @options.parser = OptionParser.parse(@args) do |parser|
        parser.banner = "Usage: shoo [subcommand] [arguments]"

        define_notification(parser)

        parser.invalid_option do |option|
          @options.errors.add("Invalid option '#{option}'")
        end

        define_help(parser)
      end

      @options
    end

    def define_notification(parser : OptionParser)
      parser.on("notification", "Commands for notifications") do
        define_purge(parser)
        define_help(parser)
      end
    end

    private def define_purge(parser : OptionParser)
      parser.on("purge", "Purge unwanted notifications") do
        parser.on("--dry-run", "Show what would be purged without actually purging") do
          @options.dry_run = true
        end

        parser.on("--verbose", "Show detailed output") do
          @options.verbose = true
        end

        parser.on("--force", "Skip purge check") do
          @options.force = true
        end

        @options.command = Commands::Purge
      end
    end

    private def define_help(parser : OptionParser)
      parser.on("help", "Show this help") { @options.show_help = true }
      parser.on("-h", "--help", "Show this help") { @options.show_help = true }
    end
  end
end
