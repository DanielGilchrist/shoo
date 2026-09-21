module APIStub
  module GitHub
    resource :graphql do
      def fail(status : Int32 = 500, message : String = "Server Error") : Nil
        @builder.fail_graphql(status, Data.error(message, status).to_json)
      end
    end
  end
end
