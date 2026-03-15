module Shoo
  struct TeamSlug
    SLUG_REGEX = /^[a-z0-9_-]+$/

    def self.parse(value : String) : TeamSlug?
      return unless value.matches?(SLUG_REGEX)

      new(value)
    end

    private def initialize(@value : String)
    end

    getter value : String

    def ==(other : String) : Bool
      @value == other
    end
  end
end
