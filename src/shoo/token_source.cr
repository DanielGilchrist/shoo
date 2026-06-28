module Shoo
  abstract struct TokenSource
    getter token : GitHub::Token

    def initialize(@token : GitHub::Token)
    end

    abstract def describe : String

    # Whether this source comes from the credential saved by `auth login`,
    # as opposed to an environment variable or config-file literal that
    # takes precedence over it.
    def from_stored_credential? : Bool
      false
    end
  end
end
