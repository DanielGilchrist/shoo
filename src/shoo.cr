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
    credential_store : CredentialStore = CredentialStore::OnDisk.new,
    env : Env = Env.load,
    gh : GitHubCLI? = GitHubCLI.detect,
  ) : Context
    context = build_context(config_path, credential_store, env, gh, stdin, stdout, stderr)
    dispatch(args, context)
    context
  end

  private def build_context(config_path : String, credential_store : CredentialStore, env : Env, gh : GitHubCLI?, stdin : IO, stdout : IO, stderr : IO) : Context
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
    credential_source =
      case credential
      when Credential::Stored    then credential.token_source
      when Credential::GitHubCLI then gh.try(&.token_source)
      end
    source = config.github.token_source(env) || credential_source

    Context.new(config, credential, gh, credential_store, source, stdout, stderr, stdin)
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
