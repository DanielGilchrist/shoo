module Shoo
  # TODO: This should probably be an LRU cache
  # Currently the cache is unbounded which although unlikely could result in memory issues
  struct Cache(T)
    CACHE_KEY_JOIN = '/'

    alias Key = String

    def initialize
      @cache = {} of Key => T
    end

    def fetch(key : Key, & : -> T) : T
      @cache[key] ||= yield
    end

    def fetch(*keys : Key, &block : -> T) : T
      key = keys.join(CACHE_KEY_JOIN)
      fetch(key, &block)
    end
  end
end
