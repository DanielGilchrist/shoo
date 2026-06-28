require "../../spec_helper"

private alias Config = Shoo::Config
private alias Error = Config::Error
private alias StateRule = Config::Purge::Rules::PurgeIf::StateRule

private def load_config(yaml : String)
  Config.load(Config::Store::InMemory.new(yaml))
end

describe Shoo::Config do
  describe ".load" do
    it "returns a Config for a valid config" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            global:
              keep_if:
                author_in_teams: ["core-team"]
                mentioned: true
              purge_if:
                merged:
                  always: true
                closed:
                  after: 2d
              unsubscribe: true
        YAML

      result.should be_a(Config)
      config = result.as(Config)

      rules = config.notifications.purge.global
      rules.keep_if.author_in_teams.size.should eq(1)
      rules.keep_if.author_in_teams.first.value.should eq("core-team")
      rules.keep_if.mentioned?.should be_true
      rules.purge_if.merged.should be_a(StateRule::Always)
      rules.purge_if.closed.should be_a(StateRule::After)
      rules.unsubscribe?.should be_true
    end

    it "returns a Config for empty content" do
      load_config("").should be_a(Config)
    end

    it "returns a Config when there is no stored config" do
      Config.load(Config::Store::InMemory.new).should be_a(Config)
    end

    it "parses repo-specific rules" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            repos:
              "my-org/my-repo":
                keep_if:
                  authors: ["someone"]
                purge_if:
                  merged:
                    after: 1w
        YAML

      result.should be_a(Config)
      config = result.as(Config)

      repos = config.notifications.purge.repos
      repos.size.should eq(1)
      repos.has_key?("my-org/my-repo").should be_true

      rules = repos["my-org/my-repo"]
      rules.keep_if.authors.should eq(["someone"])
      rules.purge_if.merged.should be_a(StateRule::After)
      rules.purge_if.merged.as(StateRule::After).duration.span.should eq(7.days)
    end

    it "returns errors for invalid slugs in global rules" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            global:
              keep_if:
                author_in_teams: ["INVALID"]
        YAML

      result.should be_a(Array(Error))
    end

    it "returns errors for invalid slugs in repo rules" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            repos:
              "my-org/my-repo":
                keep_if:
                  requested_teams: ["NOT VALID"]
        YAML

      result.should be_a(Array(Error))
    end

    it "returns errors for invalid duration in purge_if" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            global:
              purge_if:
                merged:
                  after: banana
        YAML

      result.should be_a(Array(Error))
    end

    it "returns errors for mutually exclusive always and after" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            global:
              purge_if:
                closed:
                  always: true
                  after: 1d
        YAML

      result.should be_a(Array(Error))
    end

    it "collects errors from multiple repos and global" do
      result = load_config(<<-YAML)
        notifications:
          purge:
            global:
              keep_if:
                author_in_teams: ["BAD SLUG"]
            repos:
              "org/repo-a":
                purge_if:
                  merged:
                    after: nope
              "org/repo-b":
                keep_if:
                  mentioned_teams: ["ALSO BAD"]
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(3)
    end
  end
end
