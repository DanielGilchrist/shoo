module GraphQL
  struct Error
    record Location, line : Int32, column : Int32 do
      include JSON::Serializable
    end
  end
end
