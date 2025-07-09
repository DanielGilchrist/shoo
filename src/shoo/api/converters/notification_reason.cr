module Shoo
  module API
    module Converters
      module NotificationReason
        def self.from_json(value : JSON::PullParser) : API::NotificationReason
          API::NotificationReason.parse(value.read_string)
        end

        def self.to_json(value : NotificationReason, json : JSON::Builder)
          json.string(value.to_s)
        end
      end
    end
  end
end
