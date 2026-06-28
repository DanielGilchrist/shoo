require "../../../spec_helper"

describe Shoo::Commands::Auth::Logout do
  it "removes stored credentials" do
    result = run(["auth", "logout"], credential: gh_credential)

    result.stdout.to_s.should contain("Removed shoo's stored credentials")
    result.credential.should be_nil
  end

  it "reports when there is nothing to remove" do
    result = run(["auth", "logout"])

    result.stdout.to_s.should contain("No stored credentials to remove")
  end
end
