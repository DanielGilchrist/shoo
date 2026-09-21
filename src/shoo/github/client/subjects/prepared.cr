module Shoo
  module GitHub
    struct Client
      struct Subjects
        record Prepared, text : String, aliases : Hash(SubjectRef, Tuple(String, String))
      end
    end
  end
end
