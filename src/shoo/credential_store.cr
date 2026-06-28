module Shoo
  abstract class CredentialStore
    abstract def read : String?
    abstract def write(content : String) : Nil
    abstract def clear : Nil
    abstract def present? : Bool

    def load : Credential?
      raw = read
      raw ? Credential.parse(raw) : nil
    end

    def save(credential : Credential) : Nil
      write(credential.to_raw.to_yaml)
    end

    class OnDisk < CredentialStore
      PATH = "#{Path.home}/.config/shoo/credentials"

      def initialize(@path : String = PATH)
      end

      def read : String?
        File.read(@path) if File.exists?(@path)
      end

      def write(content : String) : Nil
        Dir.mkdir_p(File.dirname(@path))
        File.write(@path, content, perm: 0o600)
      end

      def clear : Nil
        File.delete(@path) if File.exists?(@path)
      end

      def present? : Bool
        File.exists?(@path)
      end
    end
  end
end
