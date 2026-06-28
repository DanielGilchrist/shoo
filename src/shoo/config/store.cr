module Shoo
  struct Config
    abstract class Store
      abstract def read : String?
      abstract def write(content : String) : Nil
      abstract def present? : Bool
      abstract def path : String
    end
  end
end
