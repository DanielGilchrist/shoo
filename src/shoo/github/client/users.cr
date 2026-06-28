module Shoo
  module GitHub
    struct Client
      struct Users
        def initialize(@request : Request)
        end

        # https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user
        def identity : Identity | Error
          @request.identity
        end
      end
    end
  end
end
