# shoo

A CLI utility for managing GitHub notifications with configurable purging rules.

## Installation

TODO: Write installation instructions here

## Usage

```bash
# Purge notifications based on your configuration
shoo notification purge
```

## Configuration

Create `~/.config/shoo/config.yml`:

```yaml
github:
  token: "your_github_token_here"  # Optional, can use SHOO_GITHUB_TOKEN env variable

notifications:
  purge:
    # Global rules (apply to all repos unless overridden)
    global:
      keep_if:
        author_in_teams: ["core-team", "security-team"]
        authors: ["DanielGilchrist", "trusted-maintainer"]
        mentioned_users: ["DanielGilchrist"]
        labels: ["urgent", "security"]
        pr_states: ["draft"]

    # Repo-specific rules (override global)
    repos:
      "my-org/critical-repo":
        keep_if:
          author_in_teams: ["core-team"]
          mentioned_users: ["DanielGilchrist"]

      "my-org/experimental-repo":
        keep_if:
          authors: ["DanielGilchrist"]
```

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
