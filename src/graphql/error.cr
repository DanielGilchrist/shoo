module GraphQL
  struct Error
    include JSON::Serializable

    alias Path = Array(String | Int32)

    getter message : String
    getter path : Path?
    getter locations : Array(Location)?
    getter extensions : JSON::Any?

    def initialize(@message : String, @path : Path? = nil, @locations : Array(Location)? = nil, @extensions : JSON::Any? = nil) : Nil
    end

    def at?(*segments : String | Int32) : Bool
      path == segments.to_a
    end
  end
end
