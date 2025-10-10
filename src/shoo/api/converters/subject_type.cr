module Shoo
  module API
    module Converters
      module SubjectType
        def self.from_json(value : JSON::PullParser) : API::SubjectType
          API::SubjectType.parse(value.read_string)
        end
      end
    end
  end
end
