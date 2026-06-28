module Shoo
  class Config
    struct Github
      GITHUB_TOKEN_PREFIX = "ghp_"

      def self.parse(raw : Raw::Github) : Github
        new(raw.config_token)
      end

      private def initialize(@config_token : String?)
      end

      def token_source(env : Env) : Authentication::TokenSource?
        configured = @config_token
        literal = configured if configured && configured.starts_with?(GITHUB_TOKEN_PREFIX)
        custom_variable = literal ? nil : configured

        if lookup = env.github_token(from: custom_variable)
          return Authentication::TokenSource::Environment.new(lookup.token, lookup.name)
        end

        return unless literal

        token = GitHub::Token.parse?(literal)
        Authentication::TokenSource::ConfigFile.new(token) if token
      end
    end
  end
end
