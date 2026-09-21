require "../spec_helper"

GraphQL.query ClientSpecViewer do
  login String
end

private def execute(transport : MemoryTransport) : GraphQL::Envelope(ClientSpecViewer) | GraphQL::Failure
  GraphQL::Client.new(transport).execute(ClientSpecViewer)
end

describe GraphQL::Client do
  it "posts the document and variables as a JSON body" do
    transport = MemoryTransport.returning(200, %({"data": {"login": "octocat"}}))

    GraphQL::Client.new(transport).execute("query($n: Int) { login }", {n: 1}, ClientSpecViewer)

    transport.requests.should eq([%({"query":"query($n: Int) { login }","variables":{"n":1}})])
  end

  it "sends a query type's document and omits variables when none are given" do
    transport = MemoryTransport.returning(200, %({"data": {"login": "octocat"}}))

    execute(transport)

    transport.requests.should eq([%({"query":"query { login }"})])
  end

  it "returns an envelope carrying data and any partial errors" do
    outcome = execute(MemoryTransport.returning(200, <<-JSON))
      {"data": {"login": "octocat"}, "errors": [{"message": "partial", "path": ["viewer", 0]}]}
      JSON

    outcome.should be_a(GraphQL::Envelope(ClientSpecViewer))
    outcome.as(GraphQL::Envelope(ClientSpecViewer)).data.login.should eq("octocat")
    outcome.as(GraphQL::Envelope(ClientSpecViewer)).error_at?("viewer", 0).try(&.message).should eq("partial")
  end

  it "returns RejectedQuery when there is no data, only errors" do
    outcome = execute(MemoryTransport.returning(200, %({"data": null, "errors": [{"message": "bad query"}]})))

    outcome.should eq(GraphQL::RejectedQuery.new([GraphQL::Error.new("bad query")]))
  end

  it "returns HTTPFailure with the retry hint on a non-success status" do
    transport = MemoryTransport.new do
      HTTP::Client::Response.new(403, "slow down", HTTP::Headers{"Retry-After" => "30"})
    end

    outcome = execute(transport)

    outcome.should be_a(GraphQL::HTTPFailure)
    outcome.as(GraphQL::HTTPFailure).status.should eq(403)
    outcome.as(GraphQL::HTTPFailure).retry_after.should eq(30.seconds)
  end

  it "returns MalformedResponse when the body is not JSON" do
    execute(MemoryTransport.returning(200, "<html>")).should be_a(GraphQL::MalformedResponse)
  end

  it "returns MalformedResponse when the data does not match the selection" do
    execute(MemoryTransport.returning(200, %({"data": {"login": 42}}))).should be_a(GraphQL::MalformedResponse)
  end

  it "returns MalformedResponse when neither data nor errors are present" do
    execute(MemoryTransport.returning(200, "{}")).should eq(GraphQL::MalformedResponse.new("response carried neither data nor errors"))
  end

  it "returns ConnectionFailure when the transport cannot reach the server" do
    transport = MemoryTransport.new { raise IO::Error.new("connection refused") }

    outcome = execute(transport)

    outcome.should be_a(GraphQL::ConnectionFailure)
    outcome.as(GraphQL::ConnectionFailure).cause.message.should eq("connection refused")
  end
end
