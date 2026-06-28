module Shoo
  struct Config
    abstract class Store
      abstract def read : String?
      abstract def write(content : String) : Nil
      abstract def exists? : Bool
      abstract def path : String
    end
  end
end
