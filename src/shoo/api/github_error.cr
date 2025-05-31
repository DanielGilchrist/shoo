require "json"

module Shoo
  struct GitHubError
    include JSON::Serializable

    module StringToUInt16Converter
      def self.from_json(value : JSON::PullParser) : UInt16
        value.read_string.to_u16
      end

      def self.to_json(value : UInt16, json : JSON::Builder)
        json.string(value.to_s)
      end
    end

    property message : String
    property documentation_url : String

    @[JSON::Field(converter: Shoo::GitHubError::StringToUInt16Converter)]
    property status : UInt16

    def initialize(@message : String, @documentation_url : String, @status : UInt16)
    end
  end
end
