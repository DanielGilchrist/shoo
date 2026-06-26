module APIStub
  module GitHub
    resource :issues do
      def get(repo : String, id : String, **issue)
        stub(:get, "/repos/#{repo}/issues/#{id}", body: Data.issue(**issue).body)
      end
    end
  end
end
