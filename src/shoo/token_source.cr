module Shoo
  abstract struct TokenSource
    getter token : GitHub::Token

    def initialize(@token : GitHub::Token)
    end

    abstract def describe : String

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
    end

    struct StoredToken < TokenSource
      def describe : String
        "stored token"
      end
    end
  end
end
