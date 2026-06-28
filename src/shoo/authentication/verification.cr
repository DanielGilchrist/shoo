module Shoo
  module Authentication
    struct Verification
      def initialize(@context : Context)
      end

      def verify(token : GitHub::Token) : GitHub::Identity
        case identity = GitHub::Client.new(token).user.identity
        in GitHub::Identity then identity
        in GitHub::Error    then @context.abort!("Could not verify token: #{identity.message}")
        end
      end
    end
  end
end
