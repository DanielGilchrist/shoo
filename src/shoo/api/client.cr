require "http/client"
require "json"

module Shoo
  module API
    struct Client
      def initialize(token : String)
        @request = Request.new(token)
      end

      def comments : Comments
        Comments.new(@request)
      end

      def notifications : Notifications
        Notifications.new(@request)
      end

      def pull_requests : PullRequests
        PullRequests.new(@request)
      end

      def issues : Issues
        Issues.new(@request)
      end

      def teams : Teams
        Teams.new(@request)
      end
    end
  end
end
