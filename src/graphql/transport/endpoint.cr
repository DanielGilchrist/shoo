module GraphQL
  abstract class Transport
    # Posts to one endpoint over a fixed set of keep-alive connections. An
    # `HTTP::Client` owns a single socket and serves one request at a time, so
    # concurrent fibers each check out their own client rather than sharing one.
    class Endpoint < Transport
      DEFAULT_CONNECTIONS = 8

      @headers : HTTP::Headers
      @target : String

      def initialize(endpoint : URI, headers : HTTP::Headers = HTTP::Headers.new, connections : Int32 = DEFAULT_CONNECTIONS) : Nil
        @target = endpoint.request_target
        @headers = headers.merge!(JSON_HEADERS)
        @clients = Channel(HTTP::Client).new(connections)
        connections.times { @clients.send(HTTP::Client.new(endpoint)) }
      end

      def post(body : String) : HTTP::Client::Response
        client = @clients.receive

        begin
          client.post(@target, headers: @headers, body: body)
        ensure
          @clients.send(client)
        end
      end
    end
  end
end
