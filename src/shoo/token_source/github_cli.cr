module Shoo
  abstract struct TokenSource
    struct GitHubCLI < TokenSource
      def describe : String
        "GitHub CLI (gh)"
      end

      def from_stored_credential? : Bool
        true
      end
    end
  end
end
