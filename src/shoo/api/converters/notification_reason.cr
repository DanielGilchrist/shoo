module Shoo
  module API
    module Converters
      module NotificationReason
        def self.from_json(value : JSON::PullParser) : API::NotificationReason
          API::NotificationReason.parse(value.read_string)
        end
      end
    end
  end
end
