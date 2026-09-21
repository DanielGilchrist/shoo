require "../spec_helper"

GraphQL.fragment FragmentSpecViewer do
  login String
  bio? { text String }
  repositories(first: 2, orderBy: :NAME) do
    nodes Array do
      name String
      stargazerCount Int32
    end
  end
end

GraphQL.fragment FragmentSpecActor do
  on User do
    login String
  end

  on Bot do
    id String
  end
end

describe "GraphQL.fragment" do
  it "derives the selection text from the declaration" do
    FragmentSpecViewer::SELECTION.should eq(
      "login bio { text } repositories(first: 2, orderBy: NAME) { nodes { name stargazerCount } }"
    )
  end

  it "marks the type as a fragment and not a query" do
    (FragmentSpecViewer < GraphQL::Fragment).should be_true
    (FragmentSpecViewer < GraphQL::Query).should be_false
  end

  it "decodes a response into snake_case getters" do
    viewer = FragmentSpecViewer.from_json(<<-JSON)
      {"login": "octocat", "bio": null, "repositories": {"nodes": [{"name": "shoo", "stargazerCount": 3}]}}
      JSON

    viewer.login.should eq("octocat")
    viewer.bio.should be_nil
    viewer.repositories.nodes.map(&.stargazer_count).should eq([3])
  end

  it "asks for __typename and each inline fragment on a discriminated fragment" do
    FragmentSpecActor::SELECTION.should eq("__typename ... on User { login } ... on Bot { id }")
  end

  it "decodes the variant named by __typename" do
    actor = FragmentSpecActor.from_json(%({"__typename": "Bot", "id": "b1"}))

    case variant = actor.variant
    in FragmentSpecActor::Bot     then variant.id.should eq("b1")
    in FragmentSpecActor::User    then fail("expected a Bot")
    in FragmentSpecActor::Unknown then fail("expected a Bot")
    end
  end

  it "decodes an undeclared __typename as Unknown" do
    actor = FragmentSpecActor.from_json(%({"__typename": "Mannequin", "login": "m"}))

    actor.variant.should eq(FragmentSpecActor::Unknown.new("Mannequin"))
  end

  it "rejects a discriminated object without __typename" do
    expect_raises(JSON::SerializableError, /__typename/) do
      FragmentSpecActor.from_json(%({"login": "octocat"}))
    end
  end
end
