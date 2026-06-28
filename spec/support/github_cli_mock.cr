class Shoo::Authentication::GitHubCLIMock < Shoo::Authentication::GitHubCLI
  getter refreshed : Array(String)
  getter logins : Int32

  def initialize(@token : Shoo::GitHub::Token? = nil, @refresh_succeeds : Bool = true, @token_after_login : Shoo::GitHub::Token? = nil)
    @refreshed = [] of String
    @logins = 0
  end

  def fetch_token : Shoo::GitHub::Token?
    @token
  end

  def login : Bool
    @logins += 1
    @token = @token_after_login
    !@token_after_login.nil?
  end

  def refresh(scope : String) : Bool
    @refreshed << scope
    @refresh_succeeds
  end
end
