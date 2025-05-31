require "./github_error"

module Shoo
  module API
    class Result(T)
      def initialize(@value : T | GitHubError)
      end
    end
  end
end
