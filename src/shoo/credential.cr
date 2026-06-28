module Shoo
  abstract struct Credential
    def self.gh : Gh
      Gh.new
    end

    def self.stored(token : GitHub::Token) : Stored
      Stored.new(token)
    end

    def self.parse(raw : String) : Credential?
      data = Raw.from_yaml(raw)

      case data.provider
      when "gh"
        Gh.new
      when "token"
        token = GitHub::Token.parse?(data.token)
        Stored.new(token) if token
      end
    rescue YAML::ParseException
      nil
    end

    abstract def to_raw : Raw
    abstract def token_source(gh : GhCli?) : TokenSource?

    struct Raw
      include YAML::Serializable

      getter provider : String
      getter token : String?

      def initialize(@provider : String, @token : String? = nil)
      end
    end
  end
end
