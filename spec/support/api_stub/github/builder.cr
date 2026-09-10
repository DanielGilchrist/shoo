module APIStub
  module GitHub
    class Builder
      def initialize : Nil
        @registered_keys = Set(String).new
      end

      def notification(**args) : Data::NotificationSpec
        Data.notification(**args)
      end

      def pull_request(**args) : Data::SubjectSpec
        Data.pull_request(**args)
      end

      def failing_pull_request(**args) : Data::SubjectSpec
        Data.failing_pull_request(**args)
      end

      def issue(**args) : Data::SubjectSpec
        Data.issue(**args)
      end

      def register(method : Symbol, path : String, query : Hash(String, String)? = nil, status : Int32 = 200, body : String = "", headers : Hash(String, String)? = nil) : Nil
        key = "#{method.to_s.upcase} #{path}"
        key += "?#{URI::Params.encode(query)}" if query
        raise "APIStub: #{key} already stubbed in this block" unless @registered_keys.add?(key)

        stub = WebMock.stub(method, GitHub.url(path))
        stub = stub.with(query: query) if query
        stub.to_return(status: status, body: body, headers: headers)
      end
    end
  end
end
