module Shoo
  module Authentication
    abstract class CredentialStore
      abstract def read : String?
      abstract def write(content : String) : Nil
      abstract def clear : Nil
      abstract def exists? : Bool

      def load : Credential?
        raw = read
        raw ? Credential.parse(raw) : nil
      end

      def save(credential : Credential) : Nil
        write(credential.to_raw.to_yaml)
      end
    end
  end
end
