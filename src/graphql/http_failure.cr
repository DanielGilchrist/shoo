module GraphQL
  record HTTPFailure, status : Int32, body : String, headers : HTTP::Headers do
    def retry_after : Time::Span?
      headers["Retry-After"]?.try(&.to_i?).try(&.seconds)
    end
  end
end
