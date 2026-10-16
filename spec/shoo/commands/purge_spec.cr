require "../../spec_helper"

private def unsubscribing_config : Shoo::Config::Store::InMemory
  Shoo::Config::Store::InMemory.new(<<-YAML)
    github:
      token: "ghp_faketoken"

    notifications:
      purge:
        global:
          unsubscribe: true
          purge_if:
            merged:
              always: true
    YAML
end

describe Shoo::Commands::Purge do
  it "purges merged notifications when forced" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      notifications.mark_as_done("1")
    end

    result = run(["notification", "purge", "--force"])

    output = result.stdout.to_s
    output.should contain("Purged")
    output.should contain("1")
  end

  it "shows what would be purged without touching the API on a dry run" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      # no mark_as_done stubbed: a dry run that purged would hit an unstubbed endpoint
    end

    result = run(["notification", "purge", "--dry-run"])

    output = result.stdout.to_s
    output.should contain("would be purged")
    output.should contain("A merged pull request")
    output.should contain("No changes will be made")
  end

  it "purges after the user confirms" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      notifications.mark_as_done("1")
    end

    result = run(["notification", "purge"], stdin: build_stdin("y"))

    result.stdout.to_s.should contain("Purged")
  end

  it "cancels without touching the API when the user declines" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      # no mark_as_done stubbed: declining must not purge
    end

    result = run(["notification", "purge"], stdin: build_stdin("n"))

    result.stdout.to_s.should contain("Purge cancelled")
  end

  it "reports nothing to purge when every notification is kept" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "comment", title: "An open pull request", repo: "org/repo",
          subject: pull_request(merged: false, state: "open")),
      )
    end

    result = run(["notification", "purge"])

    result.stdout.to_s.should contain("No notifications to purge")
  end

  it "reports the reason when a purge request fails" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A merged pull request", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      notifications.mark_as_done("1", success: false, message: "Thread is gone")
    end

    result = run(["notification", "purge", "--force"])

    output = result.stdout.to_s
    output.should contain("Failed to purge")
    output.should contain("A merged pull request")
    output.should contain("Thread is gone")
  end

  it "purges what it can and reports the rest when some requests fail" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Merged one", repo: "org/repo", id: "1",
          subject: pull_request(merged: true)),
        notification(reason: "review_requested", title: "Merged two", repo: "org/repo", id: "2",
          subject: pull_request(merged: true)),
      )
      notifications.mark_as_done("1")
      notifications.mark_as_done("2", success: false, message: "Boom")
    end

    result = run(["notification", "purge", "--force"])

    output = result.stdout.to_s
    output.should contain("Purged")
    output.should contain("Failed to purge")
    output.should contain("Merged two")
    output.should contain("Boom")
  end

  it "reports an error when fetching notifications fails" do
    APIStub::GitHub.stub do
      notifications.fail(status: 500, message: "Server Error")
    end

    result = run(["notification", "purge", "--force"])

    result.stderr.to_s.should contain("Error fetching notifications")
    result.stderr.to_s.should contain("Server Error")
  end

  it "does not purge a notification whose subject could not be verified" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Unrelated PR", repo: "org/repo",
          subject: failing_pull_request(message: "Subject boom")),
      )
      # no mark_as_done stubbed: an unverified subject must never be purged
    end

    result = run(["notification", "purge", "--force"])

    result.stdout.to_s.should contain("No notifications to purge")
    result.stderr.to_s.should be_empty
  end

  it "aborts without purging when the subject query fails" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Unrelated PR", repo: "org/repo",
          subject: pull_request(merged: true)),
      )
      graphql.fail(status: 502, message: "Subject boom")
      # no mark_as_done stubbed: a failed evaluation must purge nothing
    end

    result = run(["notification", "purge", "--force"])

    result.stderr.to_s.should contain("Error evaluating notifications")
    result.stderr.to_s.should contain("Subject boom")
  end

  it "unsubscribes from pull requests in one GraphQL batch before marking them done" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Merged one", repo: "org/repo", id: "1",
          subject: pull_request(merged: true)),
        notification(reason: "review_requested", title: "Merged two", repo: "org/repo", id: "2",
          subject: pull_request(merged: true)),
      )
      subscriptions.unsubscribe("org/repo", 1)
      subscriptions.unsubscribe("org/repo", 2)
      notifications.mark_as_done("1")
      notifications.mark_as_done("2")
      # no REST unsubscribe stubbed: subjects with a node id must go through GraphQL
    end

    result = run(["notification", "purge", "--force"], config_store: unsubscribing_config)

    output = result.stdout.to_s
    output.should contain("Purged 2 notifications")
    output.should_not contain("Failed to purge")
  end

  it "falls back to the thread subscription endpoint when there is no subject" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "A release", repo: "org/repo", id: "1"),
      )
      notifications.unsubscribe("1", success: false, message: "Thread subscription endpoint")
    end

    result = run(["notification", "purge", "--force"], config_store: unsubscribing_config)

    result.stdout.to_s.should contain("Thread subscription endpoint")
  end

  it "keeps a notification that could not be unsubscribed and reports why" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Merged one", repo: "org/repo", id: "1",
          subject: pull_request(merged: true)),
        notification(reason: "review_requested", title: "Merged two", repo: "org/repo", id: "2",
          subject: pull_request(merged: true)),
      )
      subscriptions.unsubscribe("org/repo", 1)
      subscriptions.unsubscribe("org/repo", 2, success: false, message: "Resource not accessible")
      notifications.mark_as_done("1")
      # no mark_as_done for 2: a failed unsubscribe must leave it in the inbox
    end

    result = run(["notification", "purge", "--force"], config_store: unsubscribing_config)

    output = result.stdout.to_s
    output.should contain("Failed to purge")
    output.should contain("Merged two")
    output.should contain("Resource not accessible")
  end

  it "falls back to thread subscriptions when the token lacks the notifications scope" do
    APIStub::GitHub.stub do
      notifications.list(
        notification(reason: "review_requested", title: "Merged one", repo: "org/repo", id: "1",
          subject: pull_request(merged: true)),
      )
      subscriptions.missing_scope
      notifications.unsubscribe("1", success: false, message: "Thread subscription endpoint")
    end

    result = run(["notification", "purge", "--force"], config_store: unsubscribing_config)

    result.stdout.to_s.should contain("Thread subscription endpoint")
  end
end
