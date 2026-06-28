class Shoo::Authentication::GitHubCLIMock < Shoo::Authentication::GitHubCLI
  getter refreshed : Array(String)

  def initialize(@token : Shoo::GitHub::Token? = nil, @refresh_succeeds : Bool = true)
    @refreshed = [] of String
  end

  def token : Shoo::GitHub::Token?
    @token
  end

  def refresh(scope : String) : Bool
    @refreshed << scope
    @refresh_succeeds
  end
end
