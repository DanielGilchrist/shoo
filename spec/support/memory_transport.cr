class MemoryTransport < GraphQL::Transport
  getter requests : Array(String) = [] of String

  def self.returning(status : Int32, body : String) : MemoryTransport
    new { HTTP::Client::Response.new(status, body) }
  end

  def initialize(&@respond : String -> HTTP::Client::Response) : Nil
  end

  def post(body : String) : HTTP::Client::Response
    @requests << body
    @respond.call(body)
  end
end
