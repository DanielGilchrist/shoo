require "../spec_helper"

describe Shoo::Credential do
  describe "loading from a store" do
    it "returns nil when nothing is stored" do
      memory_store.load.should be_nil
    end

    it "parses the gh provider" do
      memory_store("provider: gh\n").load.should be_a(Shoo::Credential::Gh)
    end

    it "parses a stored token" do
      memory_store("provider: token\ntoken: ghp_stored\n").load.should be_a(Shoo::Credential::Stored)
    end

    it "ignores a token provider with no token" do
      memory_store("provider: token\n").load.should be_nil
    end
  end

  describe "saving to a store" do
    it "round-trips the gh provider" do
      store = memory_store
      store.save(Shoo::Credential.gh)

      store.load.should be_a(Shoo::Credential::Gh)
    end

    it "round-trips a stored token" do
      store = memory_store
      store.save(Shoo::Credential.stored(github_token("ghp_round")))

      store.load.should be_a(Shoo::Credential::Stored)
    end
  end

  describe "#token_source" do
    it "resolves a stored token directly" do
      Shoo::Credential.stored(github_token).token_source(nil).should be_a(Shoo::TokenSource::StoredToken)
    end

    it "resolves gh through the cli" do
      gh = Shoo::GhCli::Fake.new(token: github_token("ghp_gh"))

      Shoo::Credential.gh.token_source(gh).should be_a(Shoo::TokenSource::GitHubCli)
    end

    it "yields no source when gh is unavailable" do
      Shoo::Credential.gh.token_source(nil).should be_nil
    end
  end
end
