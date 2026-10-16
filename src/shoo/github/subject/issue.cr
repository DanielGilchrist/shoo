module Shoo
  module GitHub
    module Subject
      struct Issue
        getter node_id : String
        getter author_login : String?
        getter? closed : Bool
        getter closed_at : Time?

        def initialize(@node_id : String, @author_login : String?, @closed : Bool, @closed_at : Time?) : Nil
        end
      end
    end
  end
end
