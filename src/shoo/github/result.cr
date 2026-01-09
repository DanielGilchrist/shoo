module Shoo
  module GitHub
    class Result(T)
      alias E = Error

      def self.from(response) : self
        new((response.success? ? T : E).from_json(response.body))
      end

      def initialize(@value : T | E)
      end

      def ok? : T?
        unwrap_or(nil)
      end

      def unwrap_or(default : U) : T | U forall U
        unwrap_or { default }
      end

      def unwrap_or(& : -> U) : T | U forall U
        case value = @value
        in T
          value
        in E
          yield
        end
      end

      def expect!(message : String) : T
        case value = @value
        in T
          value
        in E
          STDERR.puts "#{message}: #{value.message}"
          exit 1
        end
      end
    end
  end
end
