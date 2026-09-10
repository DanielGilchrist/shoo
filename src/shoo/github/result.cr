module Shoo
  module GitHub
    struct Result(T)
      alias E = Error

      def self.from(response : HTTP::Client::Response) : self
        new((response.success? ? T : E).from_json(response.body))
      end

      def initialize(@value : T | E) : Nil
      end

      def unwrap_or(& : E -> U) : T | U forall U
        case value = @value
        in T
          value
        in E
          yield(value)
        end
      end
    end
  end
end
