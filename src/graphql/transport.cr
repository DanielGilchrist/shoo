module GraphQL
  abstract class Transport
    JSON_HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

    abstract def post(body : String) : HTTP::Client::Response
  end
end
