module Shoo
  module Commands
    @[Kebab::Command(summary: "Manage shoo's configuration")]
    struct Config
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Init
    end
  end
end
