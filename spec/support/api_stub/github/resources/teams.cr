module APIStub
  module GitHub
    resource :teams do
      def members(organisation : String, slug : String, *logins : String) : Nil
        @builder.register_team(organisation, slug, logins.to_a)
      end
    end
  end
end
