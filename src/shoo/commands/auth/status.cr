module Shoo
  module Commands
    struct Auth
      @[Kebab::Command(summary: "Show who shoo is authenticated as")]
      struct Status
        include Kebab::Parseable

        def run(context : Context) : Nil
          source = context.token_source
          return context.stdout.puts("Not logged in. Run `shoo auth login`.") unless source

          identity = Authentication::Verification.new(context).verify(source.token)
          render(context.stdout, source, identity, context.credential)
        end

        private def render(io : IO, source : Authentication::TokenSource, identity : GitHub::Identity, credential : Authentication::Credential?) : Nil
          io.puts "#{"✓".colorize.green} Logged in to github.com as #{"@#{identity.user.login}".colorize.bold}"
          io.puts "  via     #{source.describe}"
          io.puts "  scopes  #{identity.scopes}"

          if credential && !source.from_stored_credential?
            io.puts "  #{"note".colorize.yellow}    #{source.describe} overrides a stored credential"
            io.puts "          unset it to use the credential, or `shoo auth logout` to remove it"
          end
        end
      end
    end
  end
end
