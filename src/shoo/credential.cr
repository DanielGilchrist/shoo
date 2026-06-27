module Shoo
  abstract struct Credential
    PATH = "#{Path.home}/.config/shoo/credentials"

    def self.load(path : String = PATH) : Credential?
      return unless File.exists?(path)

      parse(Raw.from_yaml(File.read(path)))
    rescue YAML::ParseException
      nil
    end

    def self.parse(raw : Raw) : Credential?
      case raw.provider
      when "gh"
        Gh.new
      when "token"
        token = GitHub::Token.parse?(raw.token)
        Stored.new(token) if token
      end
    end

    abstract def to_raw : Raw
    abstract def token_source(gh : GhCli?) : TokenSource?

    def save(path : String = PATH) : Nil
      Dir.mkdir_p(File.dirname(path))
      File.write(path, to_raw.to_yaml, perm: 0o600)
    end

    struct Raw
      include YAML::Serializable

      getter provider : String
      getter token : String?

      def initialize(@provider : String, @token : String? = nil)
      end
    end

    struct Gh < Credential
      def to_raw : Raw
        Raw.new(provider: "gh")
      end

      def token_source(gh : GhCli?) : TokenSource?
        token = gh.try(&.token)
        TokenSource::GitHubCli.new(token) if token
      end
    end

    struct Stored < Credential
      getter token : GitHub::Token

      def initialize(@token : GitHub::Token)
      end

      def to_raw : Raw
        Raw.new(provider: "token", token: @token.value)
      end

      def token_source(gh : GhCli?) : TokenSource?
        TokenSource::StoredToken.new(@token)
      end
    end
  end
end
