module Shoo
  module API
    struct Client
      struct Issues
        def initialize(@request : Request)
        end

        def get(url : String) : API::Result(Issue)
          @request.get_from_url(Issue, url)
        end
      end
    end
  end
end
