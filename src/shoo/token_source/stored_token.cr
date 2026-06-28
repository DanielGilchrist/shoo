module Shoo
  abstract struct TokenSource
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
