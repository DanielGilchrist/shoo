require "../../spec_helper"

private alias StateRule = Shoo::Config::Purge::Rules::PurgeIf::StateRule
private alias Kind = StateRule::Kind
private alias RawStateRule = StateRule::RawStateRule
private alias Error = Shoo::Config::Error

private def parse_state_rule(yaml : String, kind : Kind = :merged) : StateRule? | Error
  raw = RawStateRule.from_yaml(yaml)
  StateRule.parse(raw, kind)
end

describe Shoo::Config::Purge::Rules::PurgeIf::StateRule do
  describe ".parse" do
    context "when always is true" do
      it "returns Always" do
        result = parse_state_rule(<<-YAML)
          always: true
          YAML

        result.should be_a(StateRule::Always)
      end
    end

    context "when after is a valid duration" do
      it "returns After with parsed duration" do
        result = parse_state_rule(<<-YAML)
          after: 2d
          YAML

        result.should be_a(StateRule::After)
        after = result.as(StateRule::After)
        after.duration.span.should eq(2.days)
      end

      it "parses various duration formats" do
        ["30m", "1h", "2d", "1w"].each do |value|
          result = parse_state_rule("after: #{value}")
          result.should be_a(StateRule::After)
        end
      end
    end

    context "when neither always nor after is set" do
      it "returns nil" do
        result = parse_state_rule(<<-YAML)
          always: false
          YAML

        result.should be_nil
      end

      it "returns nil for empty YAML" do
        result = parse_state_rule("{}")
        result.should be_nil
      end
    end

    context "when both always and after are set" do
      it "returns a mutually exclusive error" do
        result = parse_state_rule(<<-YAML)
          always: true
          after: 2d
          YAML

        result.should be_a(Error)
        message = result.as(Error).message
        message.should match(/cannot have both/)
        message.should match(/merged/)
      end

      it "includes the correct state name in the error" do
        result = parse_state_rule(<<-YAML, kind: :closed)
          always: true
          after: 1d
          YAML

        result.should be_a(Error)
        result.as(Error).message.should match(/closed/)
      end
    end

    context "when after has an invalid duration format" do
      it "returns an invalid duration error" do
        result = parse_state_rule(<<-YAML)
          after: banana
          YAML

        result.should be_a(Error)
        message = result.as(Error).message
        message.should match(/invalid duration/)
        message.should match(/banana/)
      end

      it "returns an error for unitless number" do
        result = parse_state_rule(<<-YAML)
          after: "30"
          YAML

        result.should be_a(Error)
      end

      it "returns an error for negative duration" do
        result = parse_state_rule(<<-YAML)
          after: "-5d"
          YAML

        result.should be_a(Error)
      end
    end
  end
end
