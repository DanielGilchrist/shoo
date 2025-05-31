module Shoo
  module API
    class Result(T)
      alias E = GitHubError

      def initialize(@value : T | E)
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

      def map_or(default : U, &block : T -> U) : U forall U
        case value = @value
        in T
          yield(value)
        in E
          default
        end
      end
    end
  end
end
