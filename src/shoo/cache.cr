module Shoo
  # TODO: This should probably be an LRU cache
  # Currently the cache is unbounded which although unlikely could result in memory issues
  struct Cache(K, V)
    def initialize
      @cache = {} of K => V
    end

    def fetch(key : K, & : -> V) : V
      @cache[key] ||= yield
    end
  end
end
