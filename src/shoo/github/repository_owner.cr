module Shoo
  module GitHub
    struct RepositoryOwner
      include JSON::Serializable

      getter login : String
    end
  end
end
