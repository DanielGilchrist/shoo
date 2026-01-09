module Shoo
  module GitHub
    struct Client
      struct Comments
        def initialize(@request : Request)
        end

        def list(url : String) : Result(Array(Comment))
          @request.get_from_url(Array(Comment), url)
        end
      end
    end
  end
end
