module APIStub
  module GitHub
    abstract class ResourceBase
      PAGE_1 = {"page" => "1", "per_page" => "50"}

      def initialize(@builder : Builder)
      end

      protected def stub(method : Symbol, path : String, query : Hash(String, String)? = nil, status = 200, body = "", headers : Hash(String, String)? = nil)
        @builder.register(method, path, query, status, body, headers)
      end

      protected def delete(path : String, success : Bool, message = "Server Error")
        body = success ? "" : Data.error(message, 500).to_json
        stub(:delete, path, status: success ? 204 : 500, body: body)
      end

      protected def paginated(path : String, items : Array, per_page = 50)
        raise "APIStub: #{items.size} items >= per_page #{per_page}" if items.size >= per_page

        stub(:get, path, query: PAGE_1, body: items.to_json)
        stub(:get, path, query: {"page" => "2", "per_page" => per_page.to_s}, body: "[]")
      end
    end
  end
end
