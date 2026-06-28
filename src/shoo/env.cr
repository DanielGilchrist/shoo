module Shoo
  struct Env
    GITHUB_TOKEN = "SHOO_GITHUB_TOKEN"

    record Lookup, token : GitHub::Token, name : String

    def self.load : self
      new(ENV.to_h)
    end

    def initialize(@variables : Hash(String, String))
    end

    def github_token(from : String? = nil) : Lookup?
      if from && (found = lookup(from))
        return found
      end

      lookup(GITHUB_TOKEN)
    end

    private def lookup(name : String) : Lookup?
      token = GitHub::Token.parse?(@variables[name]?)
      Lookup.new(token, name) if token
    end
  end
end
