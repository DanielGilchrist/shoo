module Shoo
  module API
    class Result(T)
      alias E = GitHubError

      def initialize(@value : T | E)
      end

      def ok? : T?
        case value = @value
        in T
          value
        in E
          nil
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
