require "../spec_helper"

describe Shoo::Duration do
  describe ".parse" do
    it "parses minutes" do
      duration = Shoo::Duration.parse("30m")
      duration.should_not be_nil
      duration.not_nil!.span.should eq(30.minutes)
    end

    it "parses hours" do
      duration = Shoo::Duration.parse("2h")
      duration.should_not be_nil
      duration.not_nil!.span.should eq(2.hours)
    end

    it "parses days" do
      duration = Shoo::Duration.parse("5d")
      duration.should_not be_nil
      duration.not_nil!.span.should eq(5.days)
    end

    it "parses weeks" do
      duration = Shoo::Duration.parse("1w")
      duration.should_not be_nil
      duration.not_nil!.span.should eq(7.days)
    end

    it "parses multi-digit values" do
      duration = Shoo::Duration.parse("120m")
      duration.should_not be_nil
      duration.not_nil!.span.should eq(120.minutes)
    end

    it "returns nil for empty string" do
      Shoo::Duration.parse("").should be_nil
    end

    it "returns nil for invalid unit" do
      Shoo::Duration.parse("5x").should be_nil
    end

    it "returns nil for missing number" do
      Shoo::Duration.parse("d").should be_nil
    end

    it "returns nil for missing unit" do
      Shoo::Duration.parse("30").should be_nil
    end

    it "returns nil for negative numbers" do
      Shoo::Duration.parse("-5d").should be_nil
    end

    it "returns nil for decimal numbers" do
      Shoo::Duration.parse("1.5d").should be_nil
    end

    it "returns nil for random text" do
      Shoo::Duration.parse("banana").should be_nil
    end
  end

  describe "#elapsed_since?" do
    it "returns true when duration has elapsed" do
      duration = Shoo::Duration.parse("1h").not_nil!
      time = Time.utc - 2.hours
      duration.elapsed_since?(time).should be_true
    end

    it "returns false when duration has not elapsed" do
      duration = Shoo::Duration.parse("1h").not_nil!
      time = Time.utc - 30.minutes
      duration.elapsed_since?(time).should be_false
    end

    it "returns true when exactly elapsed" do
      duration = Shoo::Duration.parse("1h").not_nil!
      time = Time.utc - 1.hour
      duration.elapsed_since?(time).should be_true
    end
  end
end
