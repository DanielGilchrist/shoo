module Shoo
  module GitHub
    struct Client
      struct Notifications
        # https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api
        module LinkHeader
          NAME      = "Link"
          LAST_PAGE = /[?&]page=(\d+)[^>]*>;\s*rel="last"/

          def self.last_page(headers : HTTP::Headers) : Int32?
            headers[NAME]?.try { |value| LAST_PAGE.match(value).try(&.[1].to_i?) }
          end
        end
      end
    end
  end
end
