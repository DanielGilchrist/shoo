module APIStub
  module GitHub
    resource :subscriptions do
      def unsubscribe(repo : String, number : Int32, success : Bool = true, message : String = "Could not unsubscribe") : Nil
        @builder.register_unsubscribe(GitHub.node_id(repo, number), success ? nil : message)
      end

      def missing_scope : Nil
        @builder.reject_unsubscribes
      end
    end
  end
end
