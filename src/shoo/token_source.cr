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

    struct Environment < TokenSource
      def initialize(@token : GitHub::Token, @name : String)
      end

      def describe : String
        "environment variable $#{@name}"
      end
    end

    struct ConfigFile < TokenSource
      def describe : String
        "config file"
      end
    end

    struct GitHubCli < TokenSource
      def describe : String
        "GitHub CLI (gh)"
      end

      def from_stored_credential? : Bool
        true
      end
    end

    struct StoredToken < TokenSource
      def describe : String
        "stored token"
      end

      def from_stored_credential? : Bool
        true
      end
    end
  end
end
