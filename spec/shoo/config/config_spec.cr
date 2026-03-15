require "../../spec_helper"

private alias Config = Shoo::Config
private alias Error = Config::Error
private alias StateRule = Config::Purge::Rules::PurgeIf::StateRule

private def with_config_file(yaml : String, &)
  path = File.tempname("shoo_config", ".yml")

  begin
    File.write(path, yaml)
    yield path
  ensure
    File.delete(path) if File.exists?(path)
  end
end

describe Shoo::Config do
  describe ".load" do
    it "returns a Config for a valid config file" do
      with_config_file(<<-YAML) do |path|
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
        result = Config.load(path)
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
    end

    it "returns a Config for an empty config file" do
      with_config_file("") do |path|
        result = Config.load(path)
        result.should be_a(Config)
      end
    end

    it "returns a Config when file does not exist" do
      result = Config.load("/tmp/nonexistent_shoo_config_#{rand}.yml")
      result.should be_a(Config)
    end

    it "parses repo-specific rules" do
      with_config_file(<<-YAML) do |path|
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
        result = Config.load(path)
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
    end

    it "returns errors for invalid slugs in global rules" do
      with_config_file(<<-YAML) do |path|
        notifications:
          purge:
            global:
              keep_if:
                author_in_teams: ["INVALID"]
        YAML
        result = Config.load(path)
        result.should be_a(Array(Error))
      end
    end

    it "returns errors for invalid slugs in repo rules" do
      with_config_file(<<-YAML) do |path|
        notifications:
          purge:
            repos:
              "my-org/my-repo":
                keep_if:
                  requested_teams: ["NOT VALID"]
        YAML
        result = Config.load(path)
        result.should be_a(Array(Error))
      end
    end

    it "returns errors for invalid duration in purge_if" do
      with_config_file(<<-YAML) do |path|
        notifications:
          purge:
            global:
              purge_if:
                merged:
                  after: banana
        YAML
        result = Config.load(path)
        result.should be_a(Array(Error))
      end
    end

    it "returns errors for mutually exclusive always and after" do
      with_config_file(<<-YAML) do |path|
        notifications:
          purge:
            global:
              purge_if:
                closed:
                  always: true
                  after: 1d
        YAML
        result = Config.load(path)
        result.should be_a(Array(Error))
      end
    end

    it "collects errors from multiple repos and global" do
      with_config_file(<<-YAML) do |path|
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
        result = Config.load(path)
        result.should be_a(Array(Error))
        errors = result.as(Array(Error))
        errors.size.should eq(3)
      end
    end
  end
end
