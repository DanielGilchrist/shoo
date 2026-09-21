module Shoo
  module GitHub
    # What shoo knows about the issue or pull request behind a notification,
    # independent of how it was fetched.
    module Subject
      alias Any = PullRequest | Issue
    end
  end
end
