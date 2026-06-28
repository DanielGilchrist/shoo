module Shoo
  abstract struct Credential
    struct GitHubCLI < Credential
      def to_raw : Raw
        Raw.new(provider: "gh")
      end
    end
  end
end
