require "colorize"
require "http/client"
require "json"
require "kebab"
require "yaml"

require "./shoo/**"

module Shoo
  extend self

  VERSION = "0.1.0"

  class ExitProgram < Exception
    getter code : Int32

    def initialize(@code : Int32 = 0)
      super()
    end
  end

  def main(
    args : Array(String),
    *,
    stdin : IO = STDIN,
    stdout : IO = STDOUT,
    stderr : IO = STDERR,
    config_path : String = Config::Raw::CONFIG_PATH,
    env : Env = Env.system,
  ) : Context
    context = build_context(config_path, env, stdin, stdout, stderr)
    dispatch(args, context)
    context
  end

  private def build_context(config_path : String, env : Env, stdin : IO, stdout : IO, stderr : IO) : Context
    config =
      case loaded = Config.load(config_path, env)
      in Config
        loaded
      in Array(Config::Error)
        stderr.puts "Error parsing config:"
        loaded.each { |error| stderr.puts "  #{error.message}" }
        raise ExitProgram.new(1)
      end

    Context.new(config, build_client(config), stdout, stderr, stdin)
  end

  private def build_client(config : Config) : GitHub::Client?
    token = config.github.token
    return if token.nil? || token.blank?

    GitHub::Client.new(token)
  end

  private def dispatch(args : Array(String), context : Context) : Nil
    case result = Commands::Main.parse(args)
    in Commands::Main
      result.run(context)
    in Kebab::Help
      context.stdout.puts result
    in Kebab::Errors
      context.stderr.puts result
      raise ExitProgram.new(1)
    end
  end
end

{% unless flag?(:test) %}
  {% if flag?(:debug) %}
    Shoo::Debug.setup
  {% end %}

  begin
    Shoo.main(ARGV)
  rescue ex : Shoo::ExitProgram
    exit(ex.code)
  end
{% end %}
