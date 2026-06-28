module Shoo
  class Context
    getter config : Config
    getter credential : Authentication::Credential?
    getter gh : Authentication::GitHubCLI?
    getter credential_store : Authentication::CredentialStore
    getter stdout : IO
    getter stderr : IO
    getter stdin : IO

    def initialize(@config, @env : Env, @credential, @gh, @credential_store, @stdout, @stderr, @stdin)
    end

    @token_source : Tuple(Authentication::TokenSource?)?
    @client : GitHub::Client?

    def token_source : Authentication::TokenSource?
      (@token_source ||= {@config.github.token_source(@env) || credential_source})[0]
    end

    def client : GitHub::Client
      @client ||= GitHub::Client.new(authenticated_source.token)
    end

    def prompt : Prompt
      Prompt.new(@stdin, @stdout)
    end

    def abort!(message : String) : NoReturn
      @stderr.puts message
      raise ExitProgram.new(1)
    end

    private def credential_source : Authentication::TokenSource?
      credential = @credential
      case credential
      when Authentication::Credential::Stored    then credential.token_source
      when Authentication::Credential::GitHubCLI then @gh.try(&.token_source)
      end
    end

    private def authenticated_source : Authentication::TokenSource
      token_source || abort!("Not authenticated. Run `shoo auth login`.")
    end
  end
end
