require "../../../spec_helper"

describe Shoo::Commands::Auth::Logout do
  it "removes stored credentials" do
    path = File.tempname("shoo-cred")
    Shoo::Credential::Gh.new.save(path)

    result = run(["auth", "logout"], credentials_path: path)

    result.stdout.to_s.should contain("Removed shoo's stored credentials")
    File.exists?(path).should be_false
  ensure
    File.delete(path) if path && File.exists?(path)
  end

  it "reports when there is nothing to remove" do
    result = run(["auth", "logout"], credentials_path: File.tempname("shoo-none"))

    result.stdout.to_s.should contain("No stored credentials to remove")
  end
end
