module Shoo
  module Commands
    @[Kebab::Command(summary: "Manage GitHub authentication")]
    struct Auth
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Status | Login | Logout
    end
  end
end
