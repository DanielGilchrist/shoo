module Shoo
  module API
    class Result(T)
      alias E = GitHubError

      def self.from(response) : self
        new((response.success? ? T : E).from_json(response.body))
      end

      def initialize(@value : T | E)
      end

      def map(& : T -> U) : Result(U) forall U
        case value = @value
        in T
          Result(U).new(yield(value))
        in E
          Result(U).new(value)
        end
      end

      def or(& : E -> U) : T | U forall U
        case value = @value
        in T
          value
        in E
          yield(value)
        end
      end

      def or_default : T
        case value = @value
        in T
          value
        in E
          T.new
        end
      end
    end
  end
end
