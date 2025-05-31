module Shoo
  module API
    struct Notifications
      def initialize(@client : Client)
      end

      def list : API::Result(Array(Notification))
        @client.get(Array(Notification), "/notifications")
      end
    end
  end
end
