module Shoo
  class Config
    struct Github
      GITHUB_TOKEN_PREFIX = "ghp_"

      def self.parse(raw : Raw::Github) : Github
        new(raw.config_token)
      end

      private def initialize(@config_token : String?)
      end

      def token_source(env : Env) : TokenSource?
        configured = @config_token

        if configured && configured.starts_with?(GITHUB_TOKEN_PREFIX)
          token = GitHub::Token.parse?(configured)
          return TokenSource::ConfigFile.new(token) if token
        end

        lookup = env.github_token(from: configured)
        TokenSource::Environment.new(lookup.token, lookup.name) if lookup
      end
    end
  end
end
