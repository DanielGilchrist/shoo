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
    credentials_path : String = Credential::PATH,
    env : Env = Env.load,
    gh : GhCli? = GhCli.detect,
  ) : Context
    context = build_context(config_path, credentials_path, env, gh, stdin, stdout, stderr)
    dispatch(args, context)
    context
  end

  private def build_context(config_path : String, credentials_path : String, env : Env, gh : GhCli?, stdin : IO, stdout : IO, stderr : IO) : Context
    config =
      case loaded = Config.load(config_path)
      in Config
        loaded
      in Array(Config::Error)
        stderr.puts "Error parsing config:"
        loaded.each { |error| stderr.puts "  #{error.message}" }
        raise ExitProgram.new(1)
      end

    credential = Credential.load(credentials_path)
    source = config.github.token_source(env) || credential.try(&.token_source(gh))

    Context.new(config, credential, gh, credentials_path, source, stdout, stderr, stdin)
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
