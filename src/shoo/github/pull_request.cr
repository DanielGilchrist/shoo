module Shoo
  module GitHub
    struct PullRequest
      include JSON::Serializable

      getter user : User
      getter title : String

      @[JSON::Field(converter: Shoo::GitHub::Converters::SubjectState)]
      getter state : SubjectState

      getter requested_teams : Array(Team)
      getter review_comments_url : String
      getter comments_url : String
      getter? merged : Bool = false
      getter merged_at : Time?
      getter closed_at : Time?
    end
  end
end
