module Shoo
  module GitHub
    struct Client
      def initialize(token : Token) : Nil
        @request = Request.new(token)
      end

      def notifications : Notifications
        Notifications.new(@request)
      end

      def subjects : Subjects
        Subjects.new(@request.graphql)
      end

      def teams : Teams
        Teams.new(@request.graphql)
      end

      def user : Users
        Users.new(@request.graphql)
      end
    end
  end
end
