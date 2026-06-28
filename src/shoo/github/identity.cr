module Shoo
  module GitHub
    struct Identity
      getter user : User
      getter scopes : Scopes

      def initialize(@user : User, @scopes : Scopes)
      end
    end
  end
end
