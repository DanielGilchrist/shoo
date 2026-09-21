module GraphQL
  class Client
    struct Payload(T)
      include JSON::Serializable

      getter data : T?
      getter errors : Array(Error)?
    end
  end
end
