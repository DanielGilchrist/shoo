module Shoo
  module GitHub
    struct Client
      record Fetched(T), value : T, headers : HTTP::Headers
    end
  end
end
