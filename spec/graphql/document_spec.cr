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

  it "encodes strings, numbers, booleans, null, enums and lists as GraphQL literals" do
    text = GraphQL::Document.query do
      field("search", query: %(say "hi"), first: 5, ratio: 0.5, open: true, after: nil,
        type: GraphQL::Document::EnumValue.new("ISSUE"), labels: ["a", "b"] of GraphQL::Document::Scalar)
    end

    text.should eq(%(query { search(query: "say \\"hi\\"", first: 5, ratio: 0.5, open: true, after: null, type: ISSUE, labels: ["a", "b"]) }))
  end
end
