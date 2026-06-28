require "../../../spec_helper"

describe Shoo::Commands::Auth::Login do
  it "logs in with a token provided non-interactively" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications")
    end

    result = run(["auth", "login", "--token", "ghp_new"], config_fixture: "no_token")

    result.stdout.to_s.should contain("Connected as @octocat")
    result.credential.should be_a(Shoo::Authentication::Credential::Stored)
  end

  it "logs in through the gh CLI" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications")
    end

    gh = Shoo::Authentication::GitHubCLIMock.new(token: github_token("ghp_gh"))
    result = run(["auth", "login"], stdin: build_stdin("1"), gh: gh, config_fixture: "no_token")

    output = result.stdout.to_s
    output.should contain("GitHub CLI (gh)")
    output.should contain("Connected as @octocat")
    result.credential.should be_a(Shoo::Authentication::Credential::GitHubCLI)
  end

  it "drives gh auth login when gh isn't signed in yet" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications")
    end

    gh = Shoo::Authentication::GitHubCLIMock.new(token_after_login: github_token("ghp_gh"))
    result = run(["auth", "login"], stdin: build_stdin("1", "y"), gh: gh, config_fixture: "no_token")

    output = result.stdout.to_s
    output.should contain("Connected as @octocat")
    gh.logins.should eq(1)
    result.credential.should be_a(Shoo::Authentication::Credential::GitHubCLI)
  end

  it "aborts when the user declines to sign into gh" do
    gh = Shoo::Authentication::GitHubCLIMock.new
    result = run(["auth", "login"], stdin: build_stdin("1", "n"), gh: gh, config_fixture: "no_token")

    result.stderr.to_s.should contain("gh auth login")
    gh.logins.should eq(0)
    result.credential.should be_nil
  end

  it "offers to add the notifications scope when gh lacks it" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "read:org")
    end

    gh = Shoo::Authentication::GitHubCLIMock.new(token: github_token("ghp_gh"))
    result = run(["auth", "login"], stdin: build_stdin("1", "y"), gh: gh, config_fixture: "no_token")

    output = result.stdout.to_s
    output.should contain("lacks the `notifications` scope")
    gh.refreshed.should contain("notifications")
    output.should contain("Connected as @octocat")
  end

  it "logs in with a pasted token" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications")
    end

    result = run(["auth", "login"], stdin: build_stdin("1", "ghp_pasted"), config_fixture: "no_token")

    result.stdout.to_s.should contain("Connected as @octocat")
    result.credential.should be_a(Shoo::Authentication::Credential::Stored)
  end

  it "explains the environment variable option" do
    result = run(["auth", "login"], stdin: build_stdin("2"), config_fixture: "no_token")

    result.stdout.to_s.should contain("export SHOO_GITHUB_TOKEN")
  end

  it "warns when an environment variable will shadow the login" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "notifications")
    end

    result = run(
      ["auth", "login", "--token", "ghp_new"],
      config_fixture: "no_token",
      env: {"SHOO_GITHUB_TOKEN" => "ghp_env"},
    )

    result.stdout.to_s.should contain("takes precedence")
  end

  it "aborts when a pasted token verification fails" do
    APIStub::GitHub.stub do
      user.identity(status: 401)
    end

    result = run(["auth", "login", "--token", "ghp_bad"], config_fixture: "no_token")

    result.stderr.to_s.should contain("Could not verify token")
  end

  it "aborts without storing when a provided token lacks the notifications scope" do
    APIStub::GitHub.stub do
      user.identity(login: "octocat", scopes: "gist")
    end

    result = run(["auth", "login", "--token", "ghp_unscoped"], config_fixture: "no_token")

    result.stderr.to_s.should contain("lacks the `notifications` scope")
    result.credential.should be_nil
  end
end
