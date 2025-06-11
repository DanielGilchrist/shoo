module Shoo
  # TODO: This should probably be an LRU cache
  # Currently the cache is unbounded which although unlikely could result in memory issues
  struct Cache(T)
    def initialize
      @cache = {} of String => T
    end

    def fetch(key : String, & : -> T) : T
      @cache[key] ||= yield
    end
  end
end
