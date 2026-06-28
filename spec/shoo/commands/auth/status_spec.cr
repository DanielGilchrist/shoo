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

    result = run(["auth", "status"], config_fixture: :no_token, env: {"SHOO_GITHUB_TOKEN" => "ghp_env"})

    result.stdout.to_s.should contain("environment variable $SHOO_GITHUB_TOKEN")
  end

  it "lets an environment variable override a config-file token" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    result = run(["auth", "status"], env: {"SHOO_GITHUB_TOKEN" => "ghp_env"})

    result.stdout.to_s.should contain("environment variable $SHOO_GITHUB_TOKEN")
  end

  it "flags when an env var overrides a stored credential" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    result = run(
      ["auth", "status"],
      config_fixture: :no_token,
      env: {"SHOO_GITHUB_TOKEN" => "ghp_env"},
      credential: github_cli_credential,
    )

    output = result.stdout.to_s
    output.should contain("overrides a stored credential")
    output.should contain("shoo auth logout")
  end

  it "resolves a stored gh credential through the cli" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    gh = Shoo::Authentication::GitHubCLIMock.new(token: github_token("ghp_gh"))
    result = run(["auth", "status"], config_fixture: :no_token, credential: github_cli_credential, gh: gh)

    result.stdout.to_s.should contain("GitHub CLI (gh)")
  end

  it "resolves a stored token credential" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat")
    end

    result = run(["auth", "status"], config_fixture: :no_token, credential: token_credential)

    result.stdout.to_s.should contain("stored token")
  end

  it "is not logged in when a gh credential has no cli available" do
    result = run(["auth", "status"], config_fixture: :no_token, credential: github_cli_credential, gh: nil)

    result.stdout.to_s.should contain("Not logged in")
  end

  it "reports when not logged in" do
    result = run(["auth", "status"], config_fixture: :no_token)

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
