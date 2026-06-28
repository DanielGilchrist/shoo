class Shoo::Authentication::CredentialStore::InMemory < Shoo::Authentication::CredentialStore
  def initialize(@content : String? = nil)
  end

  def read : String?
    @content
  end

  def write(content : String) : Nil
    @content = content
  end

  def clear : Nil
    @content = nil
  end

  def present? : Bool
    !@content.nil?
  end
end
