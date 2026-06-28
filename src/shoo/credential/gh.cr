module Shoo
  abstract struct Credential
    struct Gh < Credential
      def to_raw : Raw
        Raw.new(provider: "gh")
      end

      def token_source(token : GitHub::Token) : TokenSource
        TokenSource::GitHubCli.new(token)
      end
    end
  end
end
