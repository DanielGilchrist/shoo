module Shoo
  module GitHub
    struct Client
      struct Notifications
        record Page(T), items : Array(T), last_page : Int32?
      end
    end
  end
end
