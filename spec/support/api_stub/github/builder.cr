module APIStub
  module GitHub
    class Builder
      GRAPHQL_PATH = "/graphql"

      def initialize : Nil
        @registered_keys = Set(String).new
        @subjects = GraphQLResponder::Subjects.new
        @teams = GraphQLResponder::Teams.new
        @unsubscribes = GraphQLResponder::Unsubscribes.new
        @unsubscribe_scope = GraphQLResponder::UnsubscribeScope.new
        @identity = nil.as(GraphQLResponder::Identity?)
        @graphql_failure = nil.as(GraphQLResponder::Failure?)
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

      def register(method : Symbol, path : String, query : Hash(String, String)? = nil, status : Int32 = 200, body : String = "", headers : Hash(String, String)? = nil) : Nil
        stub = register_stub(method, path, query)
        stub.to_return(status: status, body: body, headers: headers)
      end

      def register_subject(repo : String, number : Int32, spec : Data::SubjectSpec) : Nil
        ensure_graphql_stub
        @subjects[{repo, number}] = spec
      end

      def register_team(organisation : String, slug : String, logins : Array(String)) : Nil
        ensure_graphql_stub
        @teams[{organisation, slug}] = logins
      end

      def register_unsubscribe(node_id : String, error : String?) : Nil
        ensure_graphql_stub
        @unsubscribes[node_id] = error
      end

      def reject_unsubscribes : Nil
        ensure_graphql_stub
        @unsubscribe_scope.missing = true
      end

      def register_identity(login : String, scopes : String) : Nil
        ensure_graphql_stub
        raise "APIStub: identity already stubbed in this block" if @identity

        @identity = GraphQLResponder::Identity.new(login, scopes)
      end

      def fail_graphql(status : Int32, body : String) : Nil
        ensure_graphql_stub
        raise "APIStub: GraphQL failure already stubbed in this block" if @graphql_failure

        @graphql_failure = GraphQLResponder::Failure.new(status, body)
      end

      private def ensure_graphql_stub : Nil
        key = "POST #{GRAPHQL_PATH}"
        return unless @registered_keys.add?(key)

        WebMock.stub(:post, GitHub.url(GRAPHQL_PATH)).to_return do |request|
          GraphQLResponder.new(@subjects, @teams, @unsubscribes, @unsubscribe_scope, @identity, @graphql_failure).respond(request)
        end
      end

      private def register_stub(method : Symbol, path : String, query : Hash(String, String)?) : WebMock::Stub
        key = "#{method.to_s.upcase} #{path}"
        key += "?#{URI::Params.encode(query)}" if query
        raise "APIStub: #{key} already stubbed in this block" unless @registered_keys.add?(key)

        stub = WebMock.stub(method, GitHub.url(path))
        query ? stub.with(query: query) : stub
      end
    end
  end
end
