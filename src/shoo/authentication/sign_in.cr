module Shoo
  module Authentication
    struct SignIn
      REQUIRED_SCOPE = "notifications"
      TOKEN_URL      = "https://github.com/settings/tokens/new?scopes=notifications&description=shoo"

      def initialize(@context : Context)
      end

      def with_token(token : GitHub::Token) : Nil
        identity = verify(token)

        unless identity.scopes.permits_notifications?
          warn_missing_scope
          stdout.puts "  Create one with that scope at #{TOKEN_URL.colorize.blue}"
        end

        store(Credential.stored(token), identity)
      end

      def via_github_cli : Nil
        gh = @context.gh
        return @context.abort!("The gh CLI is not available.") unless gh

        token = gh.token
        return @context.abort!("gh is not authenticated. Run `gh auth login` first.") unless token

        identity = verify(token)
        ensure_scope(gh, identity)

        store(Credential.github_cli, identity)
      end

      def via_pasted_token : Nil
        token = GitHub::Token.parse?(@context.prompt.ask("  Paste a token (needs the `#{REQUIRED_SCOPE}` scope): "))
        return @context.abort!("No token entered.") unless token

        with_token(token)
      end

      def via_environment_variable : Nil
        io = stdout
        io.puts
        io.puts "  Export this in your shell and shoo will use it:"
        io.puts
        io.puts "    export #{Env::GITHUB_TOKEN}=<your token>"
        io.puts
      end

      private def verify(token : GitHub::Token) : GitHub::Identity
        Verification.new(@context).verify(token)
      end

      private def ensure_scope(gh : GitHubCLI, identity : GitHub::Identity) : Nil
        return if identity.scopes.permits_notifications?

        warn_missing_scope
        return unless @context.prompt.confirm("Add it now? runs `gh auth refresh -s #{REQUIRED_SCOPE}`")

        stdout.puts "  → handing off to gh…"
        return @context.abort!("gh refresh did not complete.") unless gh.refresh(REQUIRED_SCOPE)

        stdout.puts "  #{"✓".colorize.green} scope added"
      end

      private def store(credential : Credential, identity : GitHub::Identity) : Nil
        @context.credential_store.save(credential)
        stdout.puts
        stdout.puts "  #{"✓".colorize.green} Connected as #{"@#{identity.user.login}".colorize.bold}"
        stdout.puts "  Try:  #{"shoo notification list".colorize.bold}"
      end

      private def warn_missing_scope : Nil
        stdout.puts "  #{"✗".colorize.yellow} that token lacks the `#{REQUIRED_SCOPE}` scope (needed to dismiss notifications)"
      end

      private def stdout : IO
        @context.stdout
      end
    end
  end
end
