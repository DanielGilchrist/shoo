module Shoo
  struct Config
    module Template
      CONTENT = <<-YAML
        # shoo configuration — https://github.com/DanielGilchrist/shoo
        #
        # Auth: prefer `shoo auth login`. You can also set a token here, name a
        # custom environment variable to read it from, or export SHOO_GITHUB_TOKEN.
        # github:
        #   token: "ghp_your_token_here"

        notifications:
          purge:
            # Applied to every repository unless a repo below overrides it.
            global:
              # Set true to also unsubscribe, so the thread doesn't come back.
              unsubscribe: false

              # Keep a notification when any of these match.
              keep_if:
                authors: []        # GitHub logins whose PRs/issues to keep
                mentioned: false   # keep anything that @-mentions you
                # author_in_teams: ["my-org/core-team"]
                # requested_teams: ["my-org/core-team"]
                # mentioned_teams: ["my-org/core-team"]

              # Purge a notification when any of these match (wins over keep_if).
              purge_if:
                merged:
                  always: true     # drop merged PRs immediately
                closed:
                  after: 2d        # drop closed PRs/issues 2 days after they close

            # Per-repository overrides (owner/name):
            # repos:
            #   "my-org/critical-repo":
            #     keep_if:
            #       mentioned: true
            #     purge_if:
            #       closed:
            #         always: true
        YAML
    end
  end
end
