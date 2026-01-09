module Shoo
  module GitHub
    module Converters
      module NotificationReason
        def self.from_json(value : JSON::PullParser) : GitHub::NotificationReason
          GitHub::NotificationReason.parse(value.read_string)
        end
      end
    end
  end
end
