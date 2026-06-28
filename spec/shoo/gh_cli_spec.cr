require "../spec_helper"

describe Shoo::GhCli do
  describe "#token_source" do
    it "builds a gh source when a token is available" do
      Shoo::GhCli::Fake.new(token: github_token("ghp_gh")).token_source.should be_a(Shoo::TokenSource::GitHubCli)
    end

    it "is nil when no token is available" do
      Shoo::GhCli::Fake.new.token_source.should be_nil
    end
  end
end
