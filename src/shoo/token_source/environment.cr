module Shoo
  abstract struct TokenSource
    struct Environment < TokenSource
      def initialize(@token : GitHub::Token, @name : String)
      end

      def describe : String
        "environment variable $#{@name}"
      end
    end
  end
end
