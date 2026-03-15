require "../spec_helper"

describe Shoo::TeamSlug do
  describe ".parse" do
    it "parses a valid lowercase slug" do
      slug = Shoo::TeamSlug.parse("core-team")
      slug.should_not be_nil
      slug.not_nil!.value.should eq("core-team")
    end

    it "parses a slug with underscores" do
      slug = Shoo::TeamSlug.parse("my_team")
      slug.should_not be_nil
      slug.not_nil!.value.should eq("my_team")
    end

    it "parses a slug with numbers" do
      slug = Shoo::TeamSlug.parse("team123")
      slug.should_not be_nil
    end

    it "returns nil for uppercase characters" do
      Shoo::TeamSlug.parse("Core-Team").should be_nil
    end

    it "returns nil for spaces" do
      Shoo::TeamSlug.parse("core team").should be_nil
    end

    it "returns nil for special characters" do
      Shoo::TeamSlug.parse("core.team").should be_nil
    end

    it "returns nil for empty string" do
      Shoo::TeamSlug.parse("").should be_nil
    end

    it "returns nil for slashes" do
      Shoo::TeamSlug.parse("org/team").should be_nil
    end
  end

  describe "#==" do
    it "compares equal to a matching string" do
      slug = Shoo::TeamSlug.parse("core-team").not_nil!
      (slug == "core-team").should be_true
    end

    it "compares not equal to a different string" do
      slug = Shoo::TeamSlug.parse("core-team").not_nil!
      (slug == "other-team").should be_false
    end
  end
end
