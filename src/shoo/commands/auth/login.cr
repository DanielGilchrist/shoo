module Shoo
  module Commands
    struct Auth
      @[Kebab::Command(summary: "Connect shoo to GitHub")]
      struct Login
        include Kebab::Parseable

        enum Choice
          GitHubCLI
          PasteToken
          EnvironmentVariable
        end

        @[Kebab::Option(long: "token", description: "Authenticate with this token non-interactively")]
        getter token : String?

        def run(context : Context) : Nil
          warn_if_shadowed(context)

          sign_in = Authentication::SignIn.new(context)

          if raw = token
            parsed = GitHub::Token.parse?(raw)
            return context.abort!("The provided token is blank.") unless parsed
            return sign_in.with_token(parsed)
          end

          io = context.stdout
          io.puts
          io.puts "  #{"shoo".colorize.bold} · connect to GitHub"
          io.puts

          choice = context.prompt.choose("  How should shoo authenticate?", available_choices(context)) { |option| label(option) }
          return unless choice

          case choice
          in Choice::GitHubCLI           then sign_in.via_github_cli
          in Choice::PasteToken          then sign_in.via_pasted_token
          in Choice::EnvironmentVariable then sign_in.via_environment_variable
          end
        end

        private def available_choices(context : Context) : Array(Choice)
          choices = [Choice::PasteToken, Choice::EnvironmentVariable]
          choices.unshift(Choice::GitHubCLI) if github_cli_authenticated?(context)
          choices
        end

        private def label(choice : Choice) : String
          case choice
          in Choice::GitHubCLI           then "GitHub CLI (gh)  #{"← recommended".colorize.dark_gray}"
          in Choice::PasteToken          then "Paste a personal access token"
          in Choice::EnvironmentVariable then "Use an environment variable"
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

        private def github_cli_authenticated?(context : Context) : Bool
          gh = context.gh
          return false unless gh

          !gh.token.nil?
        end
      end
    end
  end
end
