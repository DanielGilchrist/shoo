module Shoo
  module Authentication
    abstract class CredentialStore
      class FileSystem < CredentialStore
        PATH = "#{Path.home}/.config/shoo/credentials"

        def initialize(@path : String = PATH)
        end

        def read : String?
          File.read(@path) if exists?
        end

        def write(content : String) : Nil
          Dir.mkdir_p(File.dirname(@path))
          File.write(@path, content, perm: 0o600)
        end

        def clear : Nil
          File.delete(@path) if exists?
        end

        def exists? : Bool
          File.exists?(@path)
        end
      end
    end
  end
end
