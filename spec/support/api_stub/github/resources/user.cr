module APIStub
  module GitHub
    resource :user do
      def identity(login : String = "octocat", scopes : String = "notifications", status : Int32 = 200) : Nil
        return @builder.register_identity(login, scopes) if status == 200

        @builder.fail_graphql(status, Data.error(status: status).to_json)
      end
    end
  end
end
