module Shoo
  struct Env
    GITHUB_TOKEN = "SHOO_GITHUB_TOKEN"

    def self.load : self
      new(ENV.to_h)
    end

    def initialize(@variables : Hash(String, String))
    end

    def github_token(from : String? = nil) : String?
      from.try { |name| @variables[name]? } || @variables[GITHUB_TOKEN]?
    end
  end
end
