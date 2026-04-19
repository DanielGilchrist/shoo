module Shoo
  struct Duration
    PATTERN = /^(\d+)(m|h|d|w)$/

    def self.parse?(value : String) : Duration?
      match = PATTERN.match(value)
      return unless match

      amount = match[1].to_i
      unit = match[2]

      span = case unit
             when "m" then amount.minutes
             when "h" then amount.hours
             when "d" then amount.days
             when "w" then (amount * 7).days
             end

      return unless span

      new(span)
    end

    private def initialize(@span : Time::Span)
    end

    getter span : Time::Span

    def elapsed_since?(time : Time) : Bool
      Time.utc - time >= @span
    end
  end
end
