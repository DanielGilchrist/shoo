module Shoo
  module Commands
    abstract struct Command
      def initialize(@config : Config, @dry_run : Bool = false, @verbose : Bool = false); end

      abstract def execute

      private def retrieve_token!
        token = @config.github.token

        if token.nil? || token.blank?
          puts "GitHub token not provided!"
          exit
        end

        token
      end
    end
  end
end
