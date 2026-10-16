require "../spec_helper"

GraphQL.fragment DocumentSpecNode do
  id String
end

describe GraphQL::Document do
  it "composes aliased fields with arguments and nested selections" do
    text = GraphQL::Document.query do
      field("repository", as: "r0", owner: "org", name: "repo") do
        field("issue", DocumentSpecNode, as: "s0", number: 7)
      end
    end

    text.should eq(%(query { r0: repository(owner: "org", name: "repo") { s0: issue(number: 7) { id } } }))
  end

  it "encodes strings, numbers, booleans, null and enums as GraphQL literals" do
    text = GraphQL::Document.query do
      field("search", DocumentSpecNode, query: %(say "hi"), first: 5, ratio: 0.5, open: true, after: nil,
        type: GraphQL::Document::EnumValue.new("ISSUE"))
    end

    text.should eq(%(query { search(query: "say \\"hi\\"", first: 5, ratio: 0.5, open: true, after: null, type: ISSUE) { id } }))
  end

  it "composes aliased mutations with input objects" do
    text = GraphQL::Document.mutation do
      field("updateSubscription", DocumentSpecNode, as: "u0",
        input: GraphQL::Document::Input{"subscribableId" => "PR_1", "state" => GraphQL::Document::EnumValue.new("UNSUBSCRIBED")})
    end

    text.should eq(%(mutation { u0: updateSubscription(input: {subscribableId: "PR_1", state: UNSUBSCRIBED}) { id } }))
  end
end
