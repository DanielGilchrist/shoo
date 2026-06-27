module Shoo
  module GitHub
    struct Token
      def self.parse?(raw : String?) : Token?
        return if raw.nil?

        stripped = raw.strip
        return if stripped.empty?

        new(stripped)
      end

      private def initialize(@value : String)
      end

      getter value : String

      def to_s(io : IO) : Nil
        io << "***"
      end

      def inspect(io : IO) : Nil
        io << "#<Shoo::GitHub::Token ***>"
      end
    end
  end
end
