module Shoo
  class Config
    class Github
      include YAML::Serializable

      DEFAULT_TOKEN_ENV   = "SHOO_GITHUB_TOKEN"
      GITHUB_TOKEN_PREFIX = "ghp_"

      getter token : String?

      def initialize
      end

      def github_token : String?
        parse_token? || ENV[DEFAULT_TOKEN_ENV]?
      end

      private def parse_token? : String?
        token = self.token
        return if token.nil?
        return token if token.starts_with?(GITHUB_TOKEN_PREFIX)

        ENV[token]?
      end
    end
  end
end
