module Shoo
  module GitHub
    module Subject
      struct PullRequest
        getter author_login : String?
        getter? merged : Bool
        getter merged_at : Time?
        getter? closed : Bool
        getter closed_at : Time?
        getter requested_team_slugs : Array(String)

        def initialize(@author_login : String?, @merged : Bool, @merged_at : Time?, @closed : Bool, @closed_at : Time?, @requested_team_slugs : Array(String)) : Nil
        end
      end
    end
  end
end
