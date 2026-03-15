require "colorize"
require "http/client"
require "json"
require "option_parser"
require "yaml"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  def main(args : Array(String))
    options = Parser.new(args).parse!
    return print_help(options) if options.empty?
    return print_errors(options) if options.errors?
    return print_help(options) if options.show_help?

    command = options.command
    return execute_command!(command, options) if command

    print_invalid_command(options)
  end

  private def print_help(options : Options)
    puts options.parser
  end

  private def print_errors(options : Options)
    puts options.errors
    puts print_help(options)
  end

  # TODO: Make this more generic
  private def execute_command!(command : Commands::Command.class, options : Options)
    case config = Config.load
    in Config
      command.new(config, options.dry_run?, options.verbose?, options.force?).execute
    in Array(Config::Error)
      puts "Error parsing config: \n#{config.map(&.message).join("\n")}"
    end
  end

  private def print_invalid_command(options : Options)
    puts "#{"Invalid command: ".colorize.red}\"#{options.args.join(" ").colorize.bold}\""
    print_help(options)
  end
end

{% unless flag?(:test) %}
  {% if flag?(:debug) %}
    Shoo::Debug.setup
  {% end %}

  Shoo.main(args: ARGV)
{% end %}
