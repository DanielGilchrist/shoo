require "../../spec_helper"

private def notification(url : String?) : Shoo::GitHub::Notification
  Shoo::GitHub::Notification.from_json({
    id:         "1",
    reason:     "review_requested",
    subject:    {title: "t", type: "PullRequest", url: url},
    repository: {name: "repo", full_name: "org/repo", owner: {login: "org"}},
  }.to_json)
end

describe Shoo::GitHub::SubjectRef do
  it "combines the repository owner and name with the number from the subject url" do
    ref = Shoo::GitHub::SubjectRef.for(notification("https://api.github.com/repos/org/repo/pulls/42"))

    ref.should eq(Shoo::GitHub::SubjectRef.new("org", "repo", 42))
  end

  it "is nil when the subject has no url" do
    Shoo::GitHub::SubjectRef.for(notification(nil)).should be_nil
  end

  it "is nil when the url does not end in a number" do
    Shoo::GitHub::SubjectRef.for(notification("https://api.github.com/repos/org/repo/pulls/latest")).should be_nil
  end
end
