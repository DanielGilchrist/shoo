require "../../spec_helper"

private alias PurgeIf = Shoo::Config::Purge::Rules::PurgeIf
private alias StateRule = PurgeIf::StateRule
private alias RawPurgeIf = PurgeIf::RawPurgeIf
private alias Error = Shoo::Config::Error

private def parse_purge_if(yaml : String) : PurgeIf | Array(Error)
  raw = RawPurgeIf.from_yaml(yaml)
  PurgeIf.parse(raw)
end

describe Shoo::Config::Purge::Rules::PurgeIf do
  describe ".parse" do
    it "parses merged always" do
      result = parse_purge_if(<<-YAML)
        merged:
          always: true
        YAML

      result.should be_a(PurgeIf)
      purge_if = result.as(PurgeIf)
      purge_if.merged.should be_a(StateRule::Always)
      purge_if.closed.should be_nil
    end

    it "parses closed with after duration" do
      result = parse_purge_if(<<-YAML)
        closed:
          after: 2d
        YAML

      result.should be_a(PurgeIf)
      purge_if = result.as(PurgeIf)
      purge_if.merged.should be_nil
      purge_if.closed.should be_a(StateRule::After)
    end

    it "parses both merged and closed" do
      result = parse_purge_if(<<-YAML)
        merged:
          always: true
        closed:
          after: 1w
        YAML

      result.should be_a(PurgeIf)
      purge_if = result.as(PurgeIf)
      purge_if.merged.should be_a(StateRule::Always)
      purge_if.closed.should be_a(StateRule::After)
    end

    it "returns nil for both when neither is configured" do
      result = parse_purge_if("{}")

      result.should be_a(PurgeIf)
      purge_if = result.as(PurgeIf)
      purge_if.merged.should be_nil
      purge_if.closed.should be_nil
      purge_if.applicable?.should be_false
    end

    it "is applicable when merged is set" do
      result = parse_purge_if(<<-YAML)
        merged:
          always: true
        YAML

      result.as(PurgeIf).applicable?.should be_true
    end

    it "is applicable when closed is set" do
      result = parse_purge_if(<<-YAML)
        closed:
          after: 1d
        YAML

      result.as(PurgeIf).applicable?.should be_true
    end

    it "collects errors from both merged and closed" do
      result = parse_purge_if(<<-YAML)
        merged:
          always: true
          after: 1d
        closed:
          after: banana
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(2)
    end

    it "returns error for invalid merged duration" do
      result = parse_purge_if(<<-YAML)
        merged:
          after: nope
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(1)
      errors.first.message.not_nil!.should contain("merged")
    end

    it "returns error for invalid closed duration" do
      result = parse_purge_if(<<-YAML)
        closed:
          after: nope
        YAML

      result.should be_a(Array(Error))
      errors = result.as(Array(Error))
      errors.size.should eq(1)
      errors.first.message.not_nil!.should contain("closed")
    end
  end
end
