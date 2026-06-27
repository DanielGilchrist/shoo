module Shoo
  module Commands
    @[Kebab::Command(summary: "Manage GitHub authentication")]
    struct Auth
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Status
    end
  end
end
