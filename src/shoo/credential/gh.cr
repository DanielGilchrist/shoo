module Shoo
  abstract struct Credential
    struct Gh < Credential
      def to_raw : Raw
        Raw.new(provider: "gh")
      end

      def token_source(gh : GhCli?) : TokenSource?
        token = gh.try(&.token)
        TokenSource::GitHubCli.new(token) if token
      end
    end
  end
end
