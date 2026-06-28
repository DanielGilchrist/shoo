module Shoo
  class Context
    getter config : Config
    getter credential : Credential?
    getter gh : GitHubCLI?
    getter credential_store : CredentialStore
    getter token_source : TokenSource?
    getter stdout : IO
    getter stderr : IO
    getter stdin : IO

    def initialize(@config, @credential, @gh, @credential_store, @token_source, @stdout, @stderr, @stdin)
    end

    @client : GitHub::Client?

    def client : GitHub::Client
      @client ||= GitHub::Client.new(authenticated_source.token)
    end

    def abort!(message : String) : NoReturn
      @stderr.puts message
      raise ExitProgram.new(1)
    end

    private def authenticated_source : TokenSource
      @token_source || abort!("Not authenticated. Run `shoo auth login`.")
    end
  end
end
