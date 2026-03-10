require "../../spec_helper"

private alias KeepIf = Shoo::Config::Purge::Rules::KeepIf
private alias RawKeepIf = KeepIf::RawKeepIf
private alias Error = Shoo::Config::Error

private def parse_keep_if(yaml : String) : KeepIf | Array(Error)
  raw = RawKeepIf.from_yaml(yaml)
  KeepIf.parse(raw)
end

describe Shoo::Config::Purge::Rules::KeepIf do
  describe ".parse" do
    it "parses valid team slugs" do
      result = parse_keep_if(<<-YAML)
        author_in_teams: ["core-team", "backend"]
        requested_teams: ["reviewers"]
        mentioned_teams: ["platform"]
        YAML

      result.should be_a(KeepIf)
      keep_if = result.as(KeepIf)

      keep_if.author_in_teams.size.should eq(2)
      keep_if.author_in_teams[0].value.should eq("core-team")
      keep_if.author_in_teams[1].value.should eq("backend")
      keep_if.requested_teams.size.should eq(1)
      keep_if.requested_teams[0].value.should eq("reviewers")
      keep_if.mentioned_teams.size.should eq(1)
      keep_if.mentioned_teams[0].value.should eq("platform")
    end

    it "parses authors as plain strings" do
      result = parse_keep_if(<<-YAML)
        authors: ["DanielGilchrist", "SomeUser"]
        YAML

      result.should be_a(KeepIf)
      keep_if = result.as(KeepIf)
      keep_if.authors.should eq(["DanielGilchrist", "SomeUser"])
    end

    it "parses mentioned flag" do
      result = parse_keep_if(<<-YAML)
        mentioned: true
        YAML

      result.should be_a(KeepIf)
      result.as(KeepIf).mentioned?.should be_true
    end

    it "defaults mentioned to false" do
      result = parse_keep_if(<<-YAML)
        authors: []
        YAML

      result.should be_a(KeepIf)
      result.as(KeepIf).mentioned?.should be_false
    end

    it "defaults all arrays to empty" do
      result = parse_keep_if(<<-YAML)
        mentioned: false
        YAML

      result.should be_a(KeepIf)
      keep_if = result.as(KeepIf)
      keep_if.author_in_teams.should be_empty
      keep_if.requested_teams.should be_empty
      keep_if.mentioned_teams.should be_empty
      keep_if.authors.should be_empty
    end

    it "returns errors for invalid author_in_teams slugs" do
      result = parse_keep_if(<<-YAML)
        author_in_teams: ["Valid-slug", "INVALID"]
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(2)
    end

    it "returns errors for invalid requested_teams slugs" do
      result = parse_keep_if(<<-YAML)
        requested_teams: ["has spaces"]
        YAML

      result.should be_a(Array(Error))
    end

    it "returns errors for invalid mentioned_teams slugs" do
      result = parse_keep_if(<<-YAML)
        mentioned_teams: ["org/team"]
        YAML

      result.should be_a(Array(Error))
    end

    it "collects errors from all slug fields" do
      result = parse_keep_if(<<-YAML)
        author_in_teams: ["BAD"]
        requested_teams: ["ALSO BAD"]
        mentioned_teams: ["STILL BAD"]
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(3)
    end
  end
end
