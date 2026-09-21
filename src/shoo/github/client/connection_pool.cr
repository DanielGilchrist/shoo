module Shoo
  module GitHub
    struct Client
      # Reuses a bounded set of keep-alive HTTP clients so we pay the TLS handshake
      # once per connection rather than once per request. Idle clients are kept as
      # a stack, so a request that follows another reuses the warm connection
      # instead of opening a cold one. The size caps concurrent GitHub requests.
      class ConnectionPool
        DEFAULT_SIZE = 25

        def initialize(@host : String, size : Int32 = DEFAULT_SIZE) : Nil
          @tls = OpenSSL::SSL::Context::Client.new
          @idle = Array(HTTP::Client).new(size)
          @permits = Channel(Nil).new(size)
          size.times { @permits.send(nil) }
        end

        def checkout(& : HTTP::Client -> T) : T forall T
          @permits.receive
          client = @idle.pop? || HTTP::Client.new(@host, tls: @tls)

          begin
            yield client
          ensure
            @idle.push(client)
            @permits.send(nil)
          end
        end
      end
    end
  end
end
