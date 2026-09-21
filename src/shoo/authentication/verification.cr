module Shoo
  module Authentication
    struct Verification
      def initialize(@context : Context) : Nil
      end

      def verify(token : GitHub::Token) : GitHub::Identity
        case identity = GitHub::Client.new(token).user.identity
        in GitHub::Identity   then identity
        in ::GraphQL::Failure then @context.abort!("Could not verify token: #{GitHub.describe(identity)}")
        end
      end
    end
  end
end
