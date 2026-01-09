module Shoo
  module GitHub
    module Converters
      module SubjectType
        def self.from_json(value : JSON::PullParser) : GitHub::SubjectType
          GitHub::SubjectType.parse(value.read_string)
        end
      end
    end
  end
end
