require "../../spec_helper"

private alias Rules = Shoo::Config::Purge::Rules
private alias RawRules = Rules::RawRules
private alias Error = Shoo::Config::Error

private def parse_rules(yaml : String) : Rules | Array(Error)
  raw = RawRules.from_yaml(yaml)
  Rules.parse(raw)
end

describe Shoo::Config::Purge::Rules do
  describe ".parse" do
    it "parses valid rules with keep_if and purge_if" do
      result = parse_rules(<<-YAML)
        keep_if:
          author_in_teams: ["core-team"]
          mentioned: true
        purge_if:
          merged:
            always: true
        unsubscribe: true
        YAML

      result.should be_a(Rules)
      rules = result.as(Rules)
      rules.keep_if.author_in_teams.size.should eq(1)
      rules.keep_if.mentioned?.should be_true
      rules.purge_if.merged.should_not be_nil
      rules.unsubscribe?.should be_true
    end

    it "defaults unsubscribe to false" do
      result = parse_rules("{}")

      result.should be_a(Rules)
      result.as(Rules).unsubscribe?.should be_false
    end

    it "collects errors from both keep_if and purge_if" do
      result = parse_rules(<<-YAML)
        keep_if:
          author_in_teams: ["INVALID SLUG"]
        purge_if:
          merged:
            after: banana
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(2)
    end

    it "returns errors from keep_if only" do
      result = parse_rules(<<-YAML)
        keep_if:
          requested_teams: ["BAD SLUG"]
        YAML

      result.should be_a(Array(Error))
    end

    it "returns errors from purge_if only" do
      result = parse_rules(<<-YAML)
        purge_if:
          closed:
            always: true
            after: 1d
        YAML

      result.should be_a(Array(Error))
    end
  end
end
