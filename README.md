# shoo

A CLI utility for managing GitHub notifications with configurable filtering rules.

## Installation

TODO: Write installation instructions here

## Usage

```bash
# Connect shoo to GitHub (interactive)
shoo auth login

# Show your filtered inbox without changing anything
shoo notification list

# Purge unwanted notifications based on your configuration
shoo notification purge
```

Also see `shoo --help`:
```sh
❯ shoo --help
Manage GitHub notifications with configurable filtering rules

Usage: shoo <command>

Commands:
  auth          Manage GitHub authentication
  notification  Commands for notifications
  help          Show this help

Options:
  -h, --help  Show this help
```

## Authentication

shoo needs a GitHub token with the `notifications` scope (a `repo`-scoped token also works). The easiest way to set one up:

```bash
shoo auth login
```

It detects how you can authenticate and lets you pick:

- **GitHub CLI (`gh`)** — if you already use `gh`, shoo delegates to it and stores no token of its own (it runs `gh auth token` on demand). If you haven't signed into `gh` yet, shoo offers to run `gh auth login` for you. If your `gh` login is missing the `notifications` scope, shoo offers to add it.
- **Paste a token** - a personal access token, stored at `~/.config/shoo/credentials`.
- **Environment variable** - shoo prints the variable to export.

Check or clear the current login:

```bash
shoo auth status   # who you're logged in as, and where the token comes from
shoo auth logout   # remove shoo's stored credentials (your gh login is untouched)
```

A token is resolved in this order: `SHOO_GITHUB_TOKEN` (or a custom environment variable named in your config) → a literal token in `config.yml` → the credentials saved by `auth login`.

## Configuration

Create `~/.config/shoo/config.yml`:

```yaml
github:
  # Optional. Prefer `shoo auth login`. You can also set a literal token here,
  # name a custom environment variable to read it from, or just set SHOO_GITHUB_TOKEN.
  token: "your_github_token_here"

notifications:
  purge:
    # Global rules (apply to all repos unless overridden)
    global:
      unsubscribe: true # whether to unsubscribe from the notification so it never doesn't come back, default: false
      keep_if:
        authors: ["DanielGilchrist", "trusted-maintainer"]
        mentioned: false
      purge_if:
        merged:
          always: true # always purge merged PRs
        closed:
          after: 2d # purge closed PRs/issues 2 days after they were closed

    # Repo-specific rules (override global)
    repos:
      "my-org/critical-repo":
        keep_if:
          author_in_teams: ["core-team"] # keep if the author is a member of one of these teams (in slug form)
          requested_teams: ["core-team"] # keep if one of these teams is requested for review (in slug form)
          mentioned_teams: ["core-team"] # keep if one of these teams is mentioned (in slug form)
          mentioned: true
        purge_if:
          merged:
            after: 1w # keep merged PRs for a week before purging
          closed:
            always: true # always purge closed PRs/issues

      "my-org/experimental-repo":
        keep_if:
          authors: ["DanielGilchrist"]
```

## How it works

`purge_if` rules are evaluated first. If a notification matches a `purge_if` rule, it is purged regardless of `keep_if` rules.

`purge_if` supports `merged` and `closed` states independently:
- `always: true` — purge immediately
- `after: <duration>` — purge after the given duration has elapsed since the PR was merged / issue was closed
- Supported duration formats: `30m`, `1h`, `2d`, `1w`
- `always` and `after` are mutually exclusive

Shoo will always keep notifications for:
- PRs/issues you are subscribed to (`reason="subscribed"`)
- PRs/issues you have manually subscribed to (`reason="manual"`)
- PRs/issues you authored (`reason="author"`)
- PRs/issues you've commented on (`reason="comment"`)
- PRs/issues you've been assigned to (`reason="assign"`)

Additionally, it will keep notifications from PRs/issues where:
- The author is in your `authors` list
- The author is a member of teams listed in `author_in_teams`
- A team requested for review is one of the teams listed in `requested_teams`
- A team mentioned is one of the teams listed in `mentioned_teams`
- You were mentioned and `mentioned: true` is set

All other notifications will be marked for purging.

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/shoo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Daniel Gilchrist](https://github.com/your-github-user) - creator and maintainer
