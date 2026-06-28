require "../../spec_helper"

describe Shoo::Config::Template do
  it "renders a config that parses cleanly" do
    store = Shoo::Config::Store::InMemory.new(Shoo::Config::Template::CONTENT)

    Shoo::Config.load(store).should be_a(Shoo::Config)
  end
end
