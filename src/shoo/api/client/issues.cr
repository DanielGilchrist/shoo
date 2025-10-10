module Shoo
  module API
    class Client
      struct Issues
        def initialize(@client : Client)
        end

        def get(url : String) : API::Result(Issue)
          @client.get_from_url(Issue, url)
        end
      end
    end
  end
end
