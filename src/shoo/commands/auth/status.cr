module Shoo
  module Commands
    struct Auth
      @[Kebab::Command(summary: "Show who shoo is authenticated as")]
      struct Status
        include Kebab::Parseable

        def run(context : Context) : Nil
          source = context.token_source
          return context.stdout.puts("Not logged in. Run `shoo auth login`.") unless source

          case identity = context.client.user.identity
          in GitHub::Identity
            render(context.stdout, source, identity, context.credential)
          in GitHub::Error
            context.abort!("Could not verify token: #{identity.message}")
          end
        end

        private def render(io : IO, source : TokenSource, identity : GitHub::Identity, credential : Credential?) : Nil
          io.puts "#{"✓".colorize.green} Logged in to github.com as #{"@#{identity.user.login}".colorize.bold}"
          io.puts "  via     #{source.describe}"
          io.puts "  scopes  #{identity.scopes}"

          if credential && !source.from_stored_credential?
            io.puts "  #{"note".colorize.yellow}    a stored credential exists, but #{source.describe} takes precedence"
          end
        end
      end
    end
  end
end
