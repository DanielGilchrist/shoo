# shoo

A CLI utility for managing GitHub notifications with configurable filtering rules.

## Installation

TODO: Write installation instructions here

## Usage

```bash
# Filter notifications based on your configuration
shoo notification purge
```

## Configuration

Create `~/.config/shoo/config.yml`:

```yaml
github:
  token: "your_github_token_here"  # Optional, can provide a custom ENV variable with your token or just set SHOO_GITHUB_TOKEN

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
