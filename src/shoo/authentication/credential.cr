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

        case data.provider
        in Provider::Gh    then GitHubCLI.new
        in Provider::Token then from_token(data.token)
        in Nil             then nil
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
