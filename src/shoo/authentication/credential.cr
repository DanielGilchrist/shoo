module Shoo
  module Authentication
    abstract struct Credential
      def self.github_cli : GitHubCLI
        GitHubCLI.new
      end

      def self.personal_access_token(token : GitHub::Token) : PersonalAccessToken
        PersonalAccessToken.new(token)
      end

      def self.parse(raw : String) : Credential?
        data = Raw.from_yaml(raw)
        provider = data.provider
        return nil unless provider

        case provider
        in .gh?    then GitHubCLI.new
        in .token? then from_token(data.token)
        end
      rescue YAML::ParseException
        nil
      end

      private def self.from_token(value : String?) : PersonalAccessToken?
        token = GitHub::Token.parse?(value)
        PersonalAccessToken.new(token) if token
      end

      abstract def to_raw : Raw
    end
  end
end
