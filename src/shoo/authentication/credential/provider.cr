module Shoo
  module Authentication
    abstract struct Credential
      enum Provider
        Gh
        Token
      end
    end
  end
end
