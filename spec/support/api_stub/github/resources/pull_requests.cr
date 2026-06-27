module APIStub
  module GitHub
    resource :pull_requests do
      def get(repo : String, id : String, **pull_request)
        stub(:get, "/repos/#{repo}/pulls/#{id}", body: Data.pull_request(**pull_request).body)
      end
    end
  end
end
