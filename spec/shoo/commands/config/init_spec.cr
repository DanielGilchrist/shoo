require "../../../spec_helper"

describe Shoo::Commands::Config::Init do
  it "writes a starter config when none exists" do
    store = Shoo::Config::Store::InMemory.new
    result = run(["config", "init"], config_store: store)

    result.stdout.to_s.should contain("Initialised config")
    store.exists?.should be_true
    Shoo::Config.load(store).should be_a(Shoo::Config)
  end

  it "refuses to overwrite an existing config" do
    store = Shoo::Config::Store::InMemory.new(Shoo::Config::Template::CONTENT)
    result = run(["config", "init"], config_store: store)

    result.stderr.to_s.should contain("already exists")
    store.read.should eq(Shoo::Config::Template::CONTENT)
  end

  it "overwrites an existing config with --force" do
    store = Shoo::Config::Store::InMemory.new("notifications:\n  purge:\n    global: {}\n")
    result = run(["config", "init", "--force"], config_store: store)

    result.stdout.to_s.should contain("Initialised config")
    store.read.should eq(Shoo::Config::Template::CONTENT)
  end
end
