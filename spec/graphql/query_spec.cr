require "../spec_helper"

GraphQL.query QuerySpecViewer do
  viewer do
    login String
  end
end

describe "GraphQL.query" do
  it "derives the whole document from the declaration" do
    QuerySpecViewer::DOCUMENT.should eq("query { viewer { login } }")
  end

  it "marks the type as a query" do
    (QuerySpecViewer < GraphQL::Query).should be_true
    (QuerySpecViewer < GraphQL::Fragment).should be_false
  end

  it "decodes a response" do
    QuerySpecViewer.from_json(%({"viewer": {"login": "octocat"}})).viewer.login.should eq("octocat")
  end
end
