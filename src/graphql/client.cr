module GraphQL
  class Client
    def initialize(@transport : Transport) : Nil
    end

    def execute(query : T.class) : Envelope(T) | Failure forall T
      {% T.raise "#{T} is not a GraphQL.query" unless T < ::GraphQL::Query %}
      execute(T::DOCUMENT, nil, query)
    end

    def execute(document : String, data : T.class) : Envelope(T) | Failure forall T
      execute(document, nil, data)
    end

    def execute(document : String, variables : V, data : T.class) : Envelope(T) | Failure forall V, T
      response =
        begin
          @transport.post(request_body(document, variables))
        rescue error : IO::Error
          return ConnectionFailure.new(error)
        end

      return HTTPFailure.new(response.status_code, response.body, response.headers) unless response.success?

      decode(response.body, response.headers, data)
    end

    private def request_body(document : String, variables : V) : String forall V
      JSON.build do |json|
        json.object do
          json.field("query", document)
          json.field("variables") { variables.to_json(json) } unless variables.nil?
        end
      end
    end

    private def decode(body : String, headers : HTTP::Headers, data : T.class) : Envelope(T) | Failure forall T
      payload = Payload(T).from_json(body)
      errors = payload.errors || Array(Error).new

      case value = payload.data
      in T   then Envelope(T).new(value, errors, headers)
      in Nil then errors.empty? ? MalformedResponse.new("response carried neither data nor errors") : RejectedQuery.new(errors)
      end
    rescue error : JSON::ParseException | JSON::SerializableError
      MalformedResponse.new(error.message || error.class.name)
    end
  end
end
