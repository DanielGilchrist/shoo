module Shoo
  module GitHub
    struct Repository
      include JSON::Serializable

      getter full_name : String

      def organisation_name : String
        full_name.split("/").first
      end
    end
  end
end
