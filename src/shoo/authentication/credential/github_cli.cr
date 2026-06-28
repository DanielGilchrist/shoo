module Shoo
  module Authentication
    abstract struct Credential
      struct GitHubCLI < Credential
        def to_raw : Raw
          Raw.new(provider: "gh")
        end
      end
    end
  end
end
