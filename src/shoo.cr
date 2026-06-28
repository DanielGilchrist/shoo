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
    stdin : IO,
    stdout : IO,
    stderr : IO,
    config_path : String,
    credential_store : Authentication::CredentialStore,
    env : Env,
    gh : Authentication::GitHubCLI?,
  ) : Context
    context = build_context(config_path, credential_store, env, gh, stdin, stdout, stderr)
    dispatch(args, context)
    context
  end

  private def build_context(config_path : String, credential_store : Authentication::CredentialStore, env : Env, gh : Authentication::GitHubCLI?, stdin : IO, stdout : IO, stderr : IO) : Context
    config =
      case loaded = Config.load(config_path)
      in Config
        loaded
      in Array(Config::Error)
        stderr.puts "Error parsing config:"
        loaded.each { |error| stderr.puts "  #{error.message}" }
        raise ExitProgram.new(1)
      end

    credential = credential_store.load
    Context.new(config, env, credential, gh, credential_store, stdout, stderr, stdin)
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
