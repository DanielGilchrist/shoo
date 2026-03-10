module Shoo
  module GitHub
    module Converters
      module SubjectState
        def self.from_json(value : JSON::PullParser) : GitHub::SubjectState
          GitHub::SubjectState.parse(value.read_string)
        end
      end
    end
  end
end
