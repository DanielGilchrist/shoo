module Shoo
  struct Config
    abstract class Store
      class FileSystem < Store
        PATH = "#{Path.home}/.config/shoo/config.yml"

        getter path : String

        def initialize(@path : String = PATH)
        end

        def read : String?
          File.read(@path) if File.exists?(@path)
        end

        def write(content : String) : Nil
          Dir.mkdir_p(File.dirname(@path))
          File.write(@path, content)
        end

        def present? : Bool
          File.exists?(@path)
        end
      end
    end
  end
end
