require "../spec_helper"

describe Shoo::Prompt do
  describe "#choose" do
    it "returns the chosen option" do
      Shoo::Prompt.new(build_stdin("2"), IO::Memory.new).choose("pick", ["a", "b", "c"], &.itself).should eq("b")
    end

    it "defaults to the first option on empty input" do
      Shoo::Prompt.new(build_stdin(""), IO::Memory.new).choose("pick", ["a", "b"], &.itself).should eq("a")
    end

    it "returns nil on an out-of-range choice" do
      Shoo::Prompt.new(build_stdin("9"), IO::Memory.new).choose("pick", ["a"], &.itself).should be_nil
    end

    it "rejects zero and negative input rather than wrapping" do
      Shoo::Prompt.new(build_stdin("0"), IO::Memory.new).choose("pick", ["a", "b"], &.itself).should be_nil
      Shoo::Prompt.new(build_stdin("-1"), IO::Memory.new).choose("pick", ["a", "b"], &.itself).should be_nil
    end
  end

  describe "#confirm" do
    it "is true on yes or empty input" do
      Shoo::Prompt.new(build_stdin("y"), IO::Memory.new).confirm("?").should be_true
      Shoo::Prompt.new(build_stdin(""), IO::Memory.new).confirm("?").should be_true
    end

    it "is false on no" do
      Shoo::Prompt.new(build_stdin("n"), IO::Memory.new).confirm("?").should be_false
    end
  end

  describe "#ask" do
    it "returns the stripped line" do
      Shoo::Prompt.new(build_stdin("  hi  "), IO::Memory.new).ask("> ").should eq("hi")
    end
  end
end
