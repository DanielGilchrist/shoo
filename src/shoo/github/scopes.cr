module Shoo
  module GitHub
    struct Scopes
      NOTIFICATION_SCOPES = {"notifications", "repo"}

      def self.parse(header : String?) : Scopes
        names = header.to_s
          .split(',')
          .map(&.strip)
          .reject(&.empty?)
          .to_set
        new(names)
      end

      def initialize(@names : Set(String))
      end

      def permits_notifications? : Bool
        NOTIFICATION_SCOPES.any? { |scope| @names.includes?(scope) }
      end

      def to_s(io : IO) : Nil
        io << @names.join(", ")
      end
    end
  end
end
