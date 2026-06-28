require "./shoo"

{% if flag?(:debug) %}
  Shoo::Debug.setup
{% end %}

begin
  Shoo.main(
    ARGV,
    stdin: STDIN,
    stdout: STDOUT,
    stderr: STDERR,
    config_path: Shoo::Config::Raw::CONFIG_PATH,
    credential_store: Shoo::Authentication::CredentialStore::FileSystem.new,
    env: Shoo::Env.load,
    gh: Shoo::Authentication::GitHubCLI.find,
  )
rescue ex : Shoo::ExitProgram
  exit(ex.code)
end
