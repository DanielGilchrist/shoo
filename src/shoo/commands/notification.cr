module Shoo
  module Commands
    @[Kebab::Command(summary: "Commands for notifications")]
    struct Notification
      include Kebab::Parseable

      @[Kebab::Subcommand]
      getter command : Purge | List
    end
  end
end
