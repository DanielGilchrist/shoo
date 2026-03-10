module Shoo
  module GitHub
    struct Issue
      include JSON::Serializable

      getter user : User
      getter title : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::SubjectState)]
      getter state : SubjectState

      getter comments_url : String
      getter closed_at : Time?

      def closed? : Bool
        state.closed?
      end
    end
  end
end
