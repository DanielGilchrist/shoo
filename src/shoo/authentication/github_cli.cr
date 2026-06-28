module Shoo
  module Authentication
    abstract class GitHubCLI
      abstract def token : GitHub::Token?
      abstract def refresh(scope : String) : Bool

      def token_source : TokenSource?
        resolved = token
        TokenSource::GitHubCLI.new(resolved) if resolved
      end

      def self.detect : GitHubCLI?
        System.detect
      end

      class System < GitHubCLI
        @token : GitHub::Token?
        @token_resolved = false

        def self.detect : GitHubCLI?
          Process.find_executable("gh") ? new : nil
        end

        def token : GitHub::Token?
          return @token if @token_resolved

          @token_resolved = true
          @token = GitHub::Token.parse?(capture(["auth", "token"]))
        end

        def refresh(scope : String) : Bool
          success = Process.run(
            "gh",
            ["auth", "refresh", "-s", scope],
            input: Process::Redirect::Inherit,
            output: Process::Redirect::Inherit,
            error: Process::Redirect::Inherit,
          ).success?
          @token_resolved = false if success
          success
        end

        private def capture(args : Array(String)) : String?
          output = IO::Memory.new
          status = Process.run("gh", args, output: output, error: Process::Redirect::Close)
          status.success? ? output.to_s.strip : nil
        end
      end
    end
  end
end
