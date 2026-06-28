require "../spec_helper"

describe Shoo::GitHubCLI do
  describe "#token_source" do
    it "builds a gh source when a token is available" do
      Shoo::GitHubCLIMock.new(token: github_token("ghp_gh")).token_source.should be_a(Shoo::TokenSource::GitHubCLI)
    end

    it "is nil when no token is available" do
      Shoo::GitHubCLIMock.new.token_source.should be_nil
    end
  end
end
