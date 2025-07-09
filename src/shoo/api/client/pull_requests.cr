module Shoo
  module API
    class Client
      struct PullRequests
        def initialize(@client : Client)
        end

        def get(owner : String, repo : String, number : String) : API::Result(PullRequest)
          @client.get(PullRequest, "/repos/#{owner}/#{repo}/pulls/#{number}")
        end

        def get(url : String) : API::Result(PullRequest)
          @client.get_from_url(PullRequest, url)
        end
      end
    end
  end
end
