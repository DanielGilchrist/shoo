module Shoo
  module GitHub
    struct Client
      struct PullRequests
        def initialize(@request : Request)
        end

        def get(url : String) : Result(PullRequest)
          @request.get_from_url(PullRequest, url)
        end
      end
    end
  end
end
