require "../spec_helper"

describe Shoo::Authentication::Credential do
  describe "loading from a store" do
    it "returns nil when nothing is stored" do
      memory_store.load.should be_nil
    end

    it "parses the gh provider" do
      memory_store("provider: gh\n").load.should be_a(Shoo::Authentication::Credential::GitHubCLI)
    end

    it "parses a stored token" do
      memory_store("provider: token\ntoken: ghp_stored\n").load.should be_a(Shoo::Authentication::Credential::Stored)
    end

    it "ignores a token provider with no token" do
      memory_store("provider: token\n").load.should be_nil
    end
  end

  describe "saving to a store" do
    it "round-trips the gh provider" do
      store = memory_store
      store.save(Shoo::Authentication::Credential.github_cli)

      store.load.should be_a(Shoo::Authentication::Credential::GitHubCLI)
    end

    it "round-trips a stored token" do
      store = memory_store
      store.save(Shoo::Authentication::Credential.stored(github_token("ghp_round")))

      store.load.should be_a(Shoo::Authentication::Credential::Stored)
    end
  end

  describe "#token_source" do
    it "builds a stored-token source" do
      Shoo::Authentication::Credential.stored(github_token).token_source.should be_a(Shoo::Authentication::TokenSource::StoredToken)
    end
  end
end
