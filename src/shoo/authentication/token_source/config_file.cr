module Shoo
  module Authentication
    abstract struct TokenSource
      struct ConfigFile < TokenSource
        def describe : String
          "config file"
        end
      end
    end
  end
end
