require "../../../spec_helper"

describe Shoo::Commands::Auth::Status do
  it "shows the authenticated user and source" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications, repo")
    end

    result = run(["auth", "status"])

    output = result.stdout.to_s
    output.should contain("@octocat")
    output.should contain("config file")
    output.should contain("notifications")
  end

  it "names the environment variable source" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    result = run(["auth", "status"], config_fixture: "no_token", env: {"SHOO_GITHUB_TOKEN" => "ghp_env"})

    result.stdout.to_s.should contain("environment variable $SHOO_GITHUB_TOKEN")
  end

  it "flags when an env var overrides a stored credential" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    result = run(
      ["auth", "status"],
      config_fixture: "no_token",
      env: {"SHOO_GITHUB_TOKEN" => "ghp_env"},
      credential: gh_credential,
    )

    output = result.stdout.to_s
    output.should contain("overrides a stored credential")
    output.should contain("shoo auth logout")
  end

  it "reports when not logged in" do
    result = run(["auth", "status"], config_fixture: "no_token")

    result.stdout.to_s.should contain("Not logged in")
  end

  it "reports a verification failure" do
    APIStub::GitHub.stub do
      user.identity(status: 401)
    end

    result = run(["auth", "status"])

    result.stderr.to_s.should contain("Could not verify token")
  end
end
