require "../../../spec_helper"

private def ref(number : Int32, repo : String = "repo") : Shoo::GitHub::SubjectRef
  Shoo::GitHub::SubjectRef.new("org", repo, number)
end

describe Shoo::GitHub::Client::Subjects do
  it "maps every requested ref to a node or an unresolved reason" do
    transport = MemoryTransport.returning(200, <<-JSON)
      {
        "data": {
          "r0": {
            "s0": {"__typename": "Issue", "state": "OPEN", "closedAt": null, "author": {"login": "octocat"}},
            "s1": null
          },
          "r1": null
        },
        "errors": [
          {"message": "Could not resolve #2", "path": ["r0", "s1"]},
          {"message": "Could not resolve repository", "path": ["r1"]}
        ]
      }
      JSON

    outcomes = Shoo::GitHub::Client::Subjects.new(GraphQL::Client.new(transport)).fetch([ref(1), ref(2), ref(3, "other")], with_reviewers: false)

    outcomes = outcomes.as(Shoo::GitHub::Client::Subjects::Outcomes)
    outcomes[ref(1)].should eq(Shoo::GitHub::Subject::Issue.new("octocat", false, nil))
    outcomes[ref(2)].should eq(Shoo::GitHub::Unresolved.new("Could not resolve #2"))
    outcomes[ref(3, "other")].should eq(Shoo::GitHub::Unresolved.new("Could not resolve repository"))
  end

  it "groups subjects by repository under aliased fields" do
    transport = MemoryTransport.returning(200, %({"data": {"r0": {"s0": null, "s1": null}, "r1": {"s0": null}}}))

    Shoo::GitHub::Client::Subjects.new(GraphQL::Client.new(transport)).fetch([ref(1), ref(2), ref(3, "other")], with_reviewers: false)

    query = JSON.parse(transport.requests.first)["query"].as_s
    query.should contain(%(r0: repository(owner: "org", name: "repo") { s0: issueOrPullRequest(number: 1) {))
    query.should contain(%(s1: issueOrPullRequest(number: 2) {))
    query.should contain(%(r1: repository(owner: "org", name: "other") { s0: issueOrPullRequest(number: 3) {))
  end

  it "splits large batches across requests" do
    transport = MemoryTransport.returning(200, %({"data": {}}))
    refs = (1..150).map { |number| ref(number) }

    outcomes = Shoo::GitHub::Client::Subjects.new(GraphQL::Client.new(transport)).fetch(refs, with_reviewers: false)

    transport.requests.size.should eq(2)
    outcomes.as(Shoo::GitHub::Client::Subjects::Outcomes).size.should eq(150)
  end

  it "selects review requests only when asked" do
    transport = MemoryTransport.returning(200, %({"data": {"r0": {"s0": null}}}))
    subjects = Shoo::GitHub::Client::Subjects.new(GraphQL::Client.new(transport))

    subjects.fetch([ref(1)], with_reviewers: false)
    subjects.fetch([ref(1)], with_reviewers: true)

    transport.requests[0].should_not contain("reviewRequests")
    transport.requests[1].should contain("reviewRequests(first: 20)")
  end

  it "surfaces a failed request instead of partial outcomes" do
    transport = MemoryTransport.returning(502, "bad gateway")

    outcome = Shoo::GitHub::Client::Subjects.new(GraphQL::Client.new(transport)).fetch([ref(1)], with_reviewers: false)

    outcome.should be_a(GraphQL::HTTPFailure)
  end
end
