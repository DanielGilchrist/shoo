module Shoo
  abstract struct TokenSource
    struct ConfigFile < TokenSource
      def describe : String
        "config file"
      end
    end
  end
end
