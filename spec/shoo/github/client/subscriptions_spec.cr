require "../../../spec_helper"

private def subscriptions(transport : MemoryTransport) : Shoo::GitHub::Client::Subscriptions
  Shoo::GitHub::Client::Subscriptions.new(GraphQL::Client.new(transport))
end

describe Shoo::GitHub::Client::Subscriptions do
  it "unsubscribes from every subject in one aliased mutation" do
    transport = MemoryTransport.returning(200, %({"data": {"u0": {"clientMutationId": null}, "u1": {"clientMutationId": null}}}))

    outcomes = subscriptions(transport).unsubscribe(["PR_1", "I_2"])

    outcomes.should eq({"PR_1" => nil, "I_2" => nil})
    transport.requests.size.should eq(1)
    query = JSON.parse(transport.requests.first)["query"].as_s
    query.should contain(%(u0: updateSubscription(input: {subscribableId: "PR_1", state: UNSUBSCRIBED})))
    query.should contain(%(u1: updateSubscription(input: {subscribableId: "I_2", state: UNSUBSCRIBED})))
  end

  it "reports the error for each mutation that failed" do
    transport = MemoryTransport.returning(200, <<-JSON)
      {
        "data": {"u0": {"clientMutationId": null}, "u1": null},
        "errors": [{"message": "Could not resolve to a node", "path": ["u1"]}]
      }
      JSON

    outcomes = subscriptions(transport).unsubscribe(["PR_1", "PR_2"])

    outcomes.should eq({"PR_1" => nil, "PR_2" => Shoo::GitHub::Unresolved.new("Could not resolve to a node")})
  end

  it "marks a whole chunk unresolved when its request fails" do
    transport = MemoryTransport.returning(502, %({"message": "Bad Gateway", "status": "502"}))

    outcomes = subscriptions(transport).unsubscribe(["PR_1", "PR_2"])

    outcomes.should eq({"PR_1" => Shoo::GitHub::Unresolved.new("Bad Gateway"), "PR_2" => Shoo::GitHub::Unresolved.new("Bad Gateway")})
  end

  it "splits large batches across requests" do
    transport = MemoryTransport.returning(200, %({"data": {}}))

    outcomes = subscriptions(transport).unsubscribe((1..120).map { |number| "PR_#{number}" })

    transport.requests.size.should eq(3)
    outcomes.as(Shoo::GitHub::Client::Subscriptions::Outcomes).size.should eq(120)
  end

  it "reports a missing scope instead of per-subject failures" do
    transport = MemoryTransport.returning(200, <<-JSON)
      {"errors": [{"type": "INSUFFICIENT_SCOPES", "message": "The 'updateSubscription' field requires one of the following scopes: ['notifications']"}]}
      JSON

    outcomes = subscriptions(transport).unsubscribe(["PR_1"])

    outcomes.should be_a(Shoo::GitHub::Client::Subscriptions::MissingScope)
  end
end
