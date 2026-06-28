module Shoo
  abstract class GhCli
    abstract def token : GitHub::Token?
    abstract def refresh(scope : String) : Bool

    def self.detect : GhCli?
      System.detect
    end

    class System < GhCli
      def self.detect : GhCli?
        Process.find_executable("gh") ? new : nil
      end

      def token : GitHub::Token?
        GitHub::Token.parse?(capture(["auth", "token"]))
      end

      def refresh(scope : String) : Bool
        Process.run(
          "gh",
          ["auth", "refresh", "-s", scope],
          input: Process::Redirect::Inherit,
          output: Process::Redirect::Inherit,
          error: Process::Redirect::Inherit,
        ).success?
      end

      private def capture(args : Array(String)) : String?
        output = IO::Memory.new
        status = Process.run("gh", args, output: output, error: Process::Redirect::Close)
        status.success? ? output.to_s.strip : nil
      end
    end
  end
end
