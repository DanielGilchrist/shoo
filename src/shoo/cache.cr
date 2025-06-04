module Shoo
  struct Cache(T)
    def initialize
      @storage = {} of String => T
    end

    def fetch(key : String, & : -> T) : T
      if @storage.has_key?(key)
        @storage[key]
      else
        result = yield
        @storage[key] = result
        result
      end
    end
  end
end
