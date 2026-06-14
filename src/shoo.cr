require "colorize"
require "http/client"
require "json"
require "kebab"
require "yaml"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  def main(args : Array(String))
    case result = Commands::Main.parse(args)
    in Commands::Main
      run!(result)
    in Kebab::Help
      puts result
    in Kebab::Errors
      STDERR.puts(result)
      exit(1)
    end
  end

  private def run!(command : Commands::Main)
    case config = Config.load
    in Config
      command.run(config)
    in Array(Config::Error)
      puts "Error parsing config:"
      config.each { |error| puts "  #{error.message}" }
      exit(1)
    end
  end
end

{% unless flag?(:test) %}
  {% if flag?(:debug) %}
    Shoo::Debug.setup
  {% end %}

  Shoo.main(args: ARGV)
{% end %}
