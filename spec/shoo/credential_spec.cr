require "../spec_helper"

describe Shoo::Credential do
  describe ".load" do
    it "returns nil when the file does not exist" do
      Shoo::Credential.load(File.tempname("shoo-missing")).should be_nil
    end

    it "parses the gh provider" do
      path = File.tempname("shoo-cred")
      File.write(path, "provider: gh\n")

      Shoo::Credential.load(path).should be_a(Shoo::Credential::Gh)
    ensure
      File.delete(path) if path && File.exists?(path)
    end

    it "parses a stored token" do
      path = File.tempname("shoo-cred")
      File.write(path, "provider: token\ntoken: ghp_stored\n")

      Shoo::Credential.load(path).should be_a(Shoo::Credential::Stored)
    ensure
      File.delete(path) if path && File.exists?(path)
    end

    it "ignores a token provider with no token" do
      path = File.tempname("shoo-cred")
      File.write(path, "provider: token\n")

      Shoo::Credential.load(path).should be_nil
    ensure
      File.delete(path) if path && File.exists?(path)
    end
  end

  describe "#save" do
    it "writes the gh provider with owner-only permissions" do
      path = File.tempname("shoo-cred")
      Shoo::Credential::Gh.new.save(path)

      File.read(path).should contain("provider: gh")
      File.info(path).permissions.should eq(File::Permissions.new(0o600))
    ensure
      File.delete(path) if path && File.exists?(path)
    end

    it "round-trips a stored token" do
      path = File.tempname("shoo-cred")
      Shoo::Credential::Stored.new(github_token("ghp_round")).save(path)

      Shoo::Credential.load(path).should be_a(Shoo::Credential::Stored)
    ensure
      File.delete(path) if path && File.exists?(path)
    end
  end

  describe "#token_source" do
    it "resolves a stored token directly" do
      source = Shoo::Credential::Stored.new(github_token).token_source(nil)

      source.should be_a(Shoo::TokenSource::StoredToken)
    end

    it "resolves gh through the cli" do
      gh = Shoo::GhCli::Fake.new(token: github_token("ghp_gh"))

      Shoo::Credential::Gh.new.token_source(gh).should be_a(Shoo::TokenSource::GitHubCli)
    end

    it "yields no source when gh is unavailable" do
      Shoo::Credential::Gh.new.token_source(nil).should be_nil
    end
  end
end
