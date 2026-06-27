module Shoo
  module Commands
    struct Auth
      @[Kebab::Command(summary: "Remove shoo's stored credentials")]
      struct Logout
        include Kebab::Parseable

        def run(context : Context) : Nil
          path = context.credentials_path

          unless File.exists?(path)
            return context.stdout.puts("No stored credentials to remove.")
          end

          File.delete(path)
          context.stdout.puts "#{"✓".colorize.green} Removed shoo's stored credentials. Your gh login is untouched."
        end
      end
    end
  end
end
