module Shoo
  module GitHub
    struct Repository
      include JSON::Serializable

      getter name : String
      getter full_name : String
      getter owner : RepositoryOwner

      def organisation_name : String
        owner.login
      end
    end
  end
end
