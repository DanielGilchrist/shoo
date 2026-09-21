module GraphQL
  record Envelope(T), data : T, errors : Array(Error), headers : HTTP::Headers do
    def error_at?(*segments : String | Int32) : Error?
      errors.find(&.at?(*segments))
    end
  end
end
