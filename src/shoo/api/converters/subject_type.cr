module Shoo
  module API
    module Converters
      module SubjectType
        def self.from_json(value : JSON::PullParser) : API::SubjectType
          API::SubjectType.parse(value.read_string)
        end

        def self.to_json(value : SubjectType, json : JSON::Builder)
          json.string(value.to_s)
        end
      end
    end
  end
end
