module Shoo
  module Commands
    struct Auth
      @[Kebab::Command(summary: "Connect shoo to GitHub")]
      struct Login
        include Kebab::Parseable

        enum Method
          Gh
          PasteToken
          EnvVar
        end

        REQUIRED_SCOPE = "notifications"
        TOKEN_URL      = "https://github.com/settings/tokens/new?scopes=notifications&description=shoo"

        @[Kebab::Option(long: "token", description: "Authenticate with this token non-interactively")]
        getter token : String?

        def run(context : Context) : Nil
          warn_if_shadowed(context)

          if provided = token
            parsed = GitHub::Token.parse?(provided)
            return context.abort!("The provided token is blank.") unless parsed
            return connect_with_token(context, parsed)
          end

          io = context.stdout
          io.puts
          io.puts "  #{"shoo".colorize.bold} · connect to GitHub"
          io.puts

          case select_method(context, available_methods(context))
          in Method::Gh         then login_with_gh(context)
          in Method::PasteToken then login_with_pasted_token(context)
          in Method::EnvVar     then explain_environment_variable(io)
          in Nil                then io.puts "  No method selected."
          end
        end

        private def warn_if_shadowed(context : Context) : Nil
          active = context.token_source
          return unless active
          return if active.from_stored_credential?

          io = context.stdout
          io.puts "  #{"⚠".colorize.yellow} shoo is already using #{active.describe}, which takes precedence."
          io.puts "    Unset it to use this login — or keep the variable and skip logging in."
          io.puts
        end

        private def available_methods(context : Context) : Array(Method)
          methods = [] of Method
          methods << Method::Gh if gh_authenticated?(context)
          methods << Method::PasteToken
          methods << Method::EnvVar
          methods
        end

        private def gh_authenticated?(context : Context) : Bool
          gh = context.gh
          return false unless gh

          !gh.token.nil?
        end

        private def select_method(context : Context, methods : Array(Method)) : Method?
          io = context.stdout
          io.puts "  How should shoo authenticate?"
          methods.each_with_index do |method, index|
            io.puts "    #{index + 1}) #{label(method)}#{recommendation(method)}"
          end
          io.print "  Choose [1]: "

          choice = context.stdin.gets.try(&.strip)
          index = choice.nil? || choice.empty? ? 0 : choice.to_i?.try(&.pred)
          return unless index

          methods[index]?
        end

        private def label(method : Method) : String
          case method
          in Method::Gh         then "GitHub CLI (gh)"
          in Method::PasteToken then "Paste a personal access token"
          in Method::EnvVar     then "Use an environment variable"
          end
        end

        private def recommendation(method : Method) : String
          method.gh? ? "  #{"← recommended".colorize.dark_gray}" : ""
        end

        private def login_with_gh(context : Context) : Nil
          gh = context.gh
          return context.abort!("The gh CLI is not available.") unless gh

          token = gh.token
          return context.abort!("gh is not authenticated. Run `gh auth login` first.") unless token

          identity = verify!(context, token)
          ensure_gh_scope(context, gh, identity)

          context.credential_store.save(Credential.gh)
          report_success(context, identity)
        end

        private def ensure_gh_scope(context : Context, gh : GhCli, identity : GitHub::Identity) : Nil
          return if identity.scopes.permits_notifications?

          warn_missing_scope(context.stdout)
          return unless confirm(context, "Add it now? runs `gh auth refresh -s #{REQUIRED_SCOPE}`")

          context.stdout.puts "  → handing off to gh…"
          return context.abort!("gh refresh did not complete.") unless gh.refresh(REQUIRED_SCOPE)

          context.stdout.puts "  #{"✓".colorize.green} scope added"
        end

        private def login_with_pasted_token(context : Context) : Nil
          context.stdout.print "  Paste a token (needs the `#{REQUIRED_SCOPE}` scope): "
          token = GitHub::Token.parse?(context.stdin.gets)
          return context.abort!("No token entered.") unless token

          connect_with_token(context, token)
        end

        private def connect_with_token(context : Context, token : GitHub::Token) : Nil
          identity = verify!(context, token)

          unless identity.scopes.permits_notifications?
            warn_missing_scope(context.stdout)
            context.stdout.puts "  Create one with that scope at #{TOKEN_URL.colorize.blue}"
          end

          context.credential_store.save(Credential.stored(token))
          report_success(context, identity)
        end

        private def explain_environment_variable(io : IO) : Nil
          io.puts
          io.puts "  Export this in your shell and shoo will use it:"
          io.puts
          io.puts "    export #{Env::GITHUB_TOKEN}=<your token>"
          io.puts
        end

        private def verify!(context : Context, token : GitHub::Token) : GitHub::Identity
          case identity = GitHub::Client.new(token).user.identity
          in GitHub::Identity then identity
          in GitHub::Error    then context.abort!("Could not verify token: #{identity.message}")
          end
        end

        private def warn_missing_scope(io : IO) : Nil
          io.puts "  #{"✗".colorize.yellow} that token lacks the `#{REQUIRED_SCOPE}` scope (needed to dismiss notifications)"
        end

        private def report_success(context : Context, identity : GitHub::Identity) : Nil
          io = context.stdout
          io.puts
          io.puts "  #{"✓".colorize.green} Connected as #{"@#{identity.user.login}".colorize.bold}"
          io.puts "  Try:  #{"shoo notification list".colorize.bold}"
        end

        private def confirm(context : Context, prompt : String) : Bool
          context.stdout.print "  #{prompt} [Y/n]: "
          answer = context.stdin.gets.try(&.strip.downcase)
          answer.nil? || answer.empty? || answer.in?("y", "yes")
        end
      end
    end
  end
end
