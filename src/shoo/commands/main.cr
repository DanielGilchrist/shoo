module Shoo
  module Commands
    @[Kebab::Command(name: "shoo", summary: "Manage GitHub notifications with configurable filtering rules")]
    struct Main
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Notification | Auth | Config
    end
  end
end
