module Shoo
  module GitHub
    struct Client
      # Reuses a fixed set of keep-alive HTTP clients so we pay the TLS handshake
      # once per connection rather than once per request. The pool size is the cap
      # on concurrent GitHub requests, since a checkout blocks once every client is out.
      struct ConnectionPool
        DEFAULT_SIZE = 25

        def initialize(host : String, size : Int32 = DEFAULT_SIZE)
          # Clients connect lazily, so idle pool entries cost nothing; share one TLS
          # context across them rather than allocating one per client.
          tls = OpenSSL::SSL::Context::Client.new
          @clients = Channel(HTTP::Client).new(size)
          size.times { @clients.send(HTTP::Client.new(host, tls: tls)) }
        end

        def checkout(& : HTTP::Client -> T) : T forall T
          client = @clients.receive

          begin
            yield client
          ensure
            @clients.send(client)
          end
        end
      end
    end
  end
end
