require "../../spec_helper"

describe Shoo::Commands::List do
  it "lists notifications without purging" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Fix bug", repo: "org/repo"),
        notification(reason: "subscribed", title: "Bump deps", repo: "org/web"),
      )
    end

    result = run(["notification", "list"])

    output = result.stdout.to_s
    output.should contain("2 notifications across 2 repositories")
    output.should contain("org/repo")
    output.should contain("ReviewRequested")
    output.should contain("Fix bug")
    output.should contain("org/web")
    output.should contain("Bump deps")
  end

  it "tells the user when there are no notifications" do
    APIStub::GitHub.stub do
      notifications.list
    end

    result = run(["notification", "list"])

    result.stdout.to_s.should eq("No notifications.\n")
  end

  it "filters by repository with --repo" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(title: "Keep me", repo: "org/repo"),
        notification(title: "Hide me", repo: "org/other"),
      )
    end

    result = run(["notification", "list", "--repo", "org/repo"])

    output = result.stdout.to_s
    output.should contain("1 notification across 1 repository")
    output.should contain("Keep me")
    output.should_not contain("Hide me")
    output.should_not contain("org/other")
  end

  it "filters by organisation with --org" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(title: "In org", repo: "acme/web"),
        notification(title: "Other org", repo: "other/web"),
      )
    end

    result = run(["notification", "list", "--org", "acme"])

    output = result.stdout.to_s
    output.should contain("In org")
    output.should_not contain("Other org")
  end

  it "filters by reason with --reason" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Review me"),
        notification(reason: "mention", title: "Mentioned me"),
      )
    end

    result = run(["notification", "list", "--reason", "review_requested"])

    output = result.stdout.to_s
    output.should contain("Review me")
    output.should_not contain("Mentioned me")
  end

  it "filters by a case-insensitive title search with --search" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(title: "Fix the Payroll bug"),
        notification(title: "Unrelated change"),
      )
    end

    result = run(["notification", "list", "--search", "payroll"])

    output = result.stdout.to_s
    output.should contain("Fix the Payroll bug")
    output.should_not contain("Unrelated change")
  end

  it "reports when no notifications match the filters" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(title: "Keep", repo: "org/repo"),
      )
    end

    result = run(["notification", "list", "--repo", "org/none"])

    result.stdout.to_s.should eq("No notifications match the given filters.\n")
  end

  it "errors on an invalid reason with a readable message" do
    result = run(["notification", "list", "--reason", "bogus"])

    error = result.stderr.to_s
    error.should contain(%("bogus" isn't a valid notification reason for "--reason"))
    error.should contain("review_requested")
    error.should_not contain("NotificationReason")
  end

  it "shows the purge verdict with --verdict" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
    end

    result = run(["notification", "list", "--verdict"])

    output = result.stdout.to_s
    output.should contain("REMOVING (1)")
    output.should contain("Merged")
    output.should contain("A merged pull request")
  end

  it "errors when no GitHub token is configured" do
    result = run(["notification", "list"], config_fixture: "no_token")

    result.stderr.to_s.should contain("GitHub token not provided!")
  end

  it "resolves the token from an environment variable" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(title: "From env token"),
      )
    end

    result = run(["notification", "list"], config_fixture: "env_token", env: {"GH_TOKEN" => "ghp_fromenv"})

    result.stdout.to_s.should contain("From env token")
  end

  it "reports an error when fetching notifications fails" do
    APIStub::GitHub.stub do
      notifications.fail(status: 500, message: "Server Error")
    end

    result = run(["notification", "list"])

    result.stderr.to_s.should contain("Error fetching notifications")
    result.stderr.to_s.should contain("Server Error")
  end

  it "rejects stubbing the same endpoint twice in a block" do
    expect_raises(Exception, /already stubbed/) do
      APIStub::GitHub.stub do
        notifications.list(notification(id: "1"))
        notifications.list(notification(id: "2"))
      end
    end
  end
end
