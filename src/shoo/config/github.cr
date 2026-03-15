module Shoo
  class Config
    struct Github
      DEFAULT_TOKEN_ENV   = "SHOO_GITHUB_TOKEN"
      GITHUB_TOKEN_PREFIX = "ghp_"

      def self.parse(raw : Raw::Github) : Github
        new(config_token: raw.config_token)
      end

      private def initialize(@config_token : String?)
      end

      def token : String?
        parse_token? || ENV[DEFAULT_TOKEN_ENV]?
      end

      private def parse_token? : String?
        token = @config_token
        return if token.nil?
        return token if token.starts_with?(GITHUB_TOKEN_PREFIX)

        ENV[token]?
      end
    end
  end
end
