module Shoo
  abstract struct Credential
    struct Stored < Credential
      getter token : GitHub::Token

      def initialize(@token : GitHub::Token)
      end

      def to_raw : Raw
        Raw.new(provider: "token", token: @token.value)
      end

      def token_source : TokenSource
        TokenSource::StoredToken.new(@token)
      end
    end
  end
end
