module Shoo
  module Authentication
    abstract struct Credential
      struct PersonalAccessToken < Credential
        getter token : GitHub::Token

        def initialize(@token : GitHub::Token)
        end

        def to_raw : Raw
          Raw.new(provider: Provider::Token, token: @token.value)
        end

        def token_source : TokenSource
          TokenSource::StoredToken.new(@token)
        end
      end
    end
  end
end
