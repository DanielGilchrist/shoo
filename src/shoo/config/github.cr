module Shoo
  class Config
    struct Github
      DEFAULT_TOKEN_ENV   = "SHOO_GITHUB_TOKEN"
      GITHUB_TOKEN_PREFIX = "ghp_"

      def self.parse(raw : Raw::Github, env : Env) : Github
        new(resolve_token(raw.config_token, env))
      end

      private def self.resolve_token(config_token : String?, env : Env) : String?
        resolved =
          if config_token
            config_token.starts_with?(GITHUB_TOKEN_PREFIX) ? config_token : env[config_token]?
          end

        resolved || env[DEFAULT_TOKEN_ENV]?
      end

      private def initialize(@token : String?)
      end

      getter token : String?
    end
  end
end
