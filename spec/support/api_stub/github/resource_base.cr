module APIStub
  module GitHub
    abstract class ResourceBase
      PAGE_1 = {"page" => "1", "per_page" => "50"}

      def initialize(@builder : Builder) : Nil
      end

      protected def stub(method : Symbol, path : String, query : Hash(String, String)? = nil, status : Int32 = 200, body : String = "", headers : Hash(String, String)? = nil) : Nil
        @builder.register(method, path, query, status, body, headers)
      end

      protected def delete(path : String, success : Bool, message : String = "Server Error") : Nil
        body = success ? "" : Data.error(message, 500).to_json
        stub(:delete, path, status: success ? 204 : 500, body: body)
      end

      protected def paginated(path : String, items : Array, per_page : Int32 = 50) : Nil
        pages = items.each_slice(per_page).to_a
        pages = [[] of Nil] if pages.empty?

        pages.each_with_index(1) do |page, number|
          query = {"page" => number.to_s, "per_page" => per_page.to_s}
          headers = number == 1 && pages.size > 1 ? {"Link" => link_header(path, pages.size, per_page)} : nil
          stub(:get, path, query: query, body: page.to_json, headers: headers)
        end
      end

      private def link_header(path : String, last : Int32, per_page : Int32) : String
        %(<#{GitHub.url(path)}?page=2&per_page=#{per_page}>; rel="next", <#{GitHub.url(path)}?page=#{last}&per_page=#{per_page}>; rel="last")
      end
    end
  end
end
