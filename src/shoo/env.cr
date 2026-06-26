module Shoo
  struct Env
    def self.system : self
      new(ENV.to_h)
    end

    def initialize(@variables : Hash(String, String))
    end

    def []?(key : String) : String?
      @variables[key]?
    end
  end
end
