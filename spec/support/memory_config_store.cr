class Shoo::Config::Store::InMemory < Shoo::Config::Store
  def initialize(@content : String? = nil)
  end

  def read : String?
    @content
  end

  def write(content : String) : Nil
    @content = content
  end

  def exists? : Bool
    !@content.nil?
  end

  def path : String
    "(memory)"
  end
end
