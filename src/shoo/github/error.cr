module Shoo
  module GitHub
    struct Error
      include JSON::Serializable

      module StringToUInt16Converter
        def self.from_json(value : JSON::PullParser) : UInt16
          value.read_string.to_u16
        end
      end

      getter message : String
      getter documentation_url : String

      @[JSON::Field(converter: Shoo::GitHub::Error::StringToUInt16Converter)]
      getter status : UInt16
    end
  end
end
