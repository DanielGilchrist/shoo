module Shoo
  module Authentication
    abstract class GitHubCLI
      def self.find : GitHubCLI?
        System.find
      end

      abstract def fetch_token : GitHub::Token?
      abstract def login : Bool
      abstract def refresh(scope : String) : Bool

      def token_source : TokenSource?
        resolved = fetch_token
        TokenSource::GitHubCLI.new(resolved) if resolved
      end

      private class System < GitHubCLI
        COMMAND = "gh"

        def self.find : GitHubCLI?
          Process.find_executable(COMMAND) ? new : nil
        end

        def fetch_token : GitHub::Token?
          GitHub::Token.parse?(capture("auth", "token"))
        end

        def login : Bool
          interactive("auth", "login")
        end

        def refresh(scope : String) : Bool
          interactive("auth", "refresh", "-s", scope)
        end

        private def capture(*args : String) : String?
          output = IO::Memory.new
          status = Process.run(COMMAND, args.to_a, output: output, error: Process::Redirect::Close)
          status.success? ? output.to_s.strip : nil
        end

        private def interactive(*args : String) : Bool
          Process.run(
            COMMAND,
            args.to_a,
            input: Process::Redirect::Inherit,
            output: Process::Redirect::Inherit,
            error: Process::Redirect::Inherit,
          ).success?
        end
      end
    end
  end
end
