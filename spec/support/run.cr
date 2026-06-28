struct RunResult
  getter context : Shoo::Context?
  getter stdout : IO::Memory
  getter stderr : IO::Memory
  getter credential_store : Shoo::Authentication::CredentialStore
  getter config_store : Shoo::Config::Store

  def initialize(@context : Shoo::Context?, @stdout : IO::Memory, @stderr : IO::Memory, @credential_store : Shoo::Authentication::CredentialStore, @config_store : Shoo::Config::Store)
  end

  def credential : Shoo::Authentication::Credential?
    @credential_store.load
  end
end

def run(
  args : Array(String),
  config_fixture : ConfigFixtures::Name = ConfigFixtures::Name::Default,
  config_store : Shoo::Config::Store? = nil,
  env : Hash(String, String) = {} of String => String,
  stdin : IO = IO::Memory.new,
  gh : Shoo::Authentication::GitHubCLI? = nil,
  credential : Shoo::Authentication::Credential? = nil,
) : RunResult
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  credential_store = Shoo::Authentication::CredentialStore::InMemory.new
  credential_store.save(credential) if credential

  store = config_store || Shoo::Config::Store::InMemory.new(ConfigFixtures.fetch(config_fixture))

  context =
    begin
      Shoo.main(
        args,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        config_store: store,
        credential_store: credential_store,
        env: Shoo::Env.new(env),
        gh: gh,
      )
    rescue Shoo::ExitProgram
      nil
    end

  RunResult.new(context, stdout, stderr, credential_store, store)
end

def build_stdin(*lines : String) : IO
  IO::Memory.new.tap do |stdin|
    lines.each { |line| stdin.puts(line) }
    stdin.rewind
  end
end
