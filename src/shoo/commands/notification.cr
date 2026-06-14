module Shoo
  module Commands
    @[Kebab::Command(summary: "Commands for notifications")]
    struct Notification
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Purge
    end
  end
end
