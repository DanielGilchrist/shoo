CONFIG_FIXTURE_PATH = "spec/fixtures/config"

struct RunResult
  getter context : Shoo::Context?
  getter stdout : IO::Memory
  getter stderr : IO::Memory
  getter credential_store : Shoo::CredentialStore

  def initialize(@context : Shoo::Context?, @stdout : IO::Memory, @stderr : IO::Memory, @credential_store : Shoo::CredentialStore)
  end

  def credential : Shoo::Credential?
    @credential_store.load
  end
end

def run(
  args : Array(String),
  config_fixture : String = "default",
  env : Hash(String, String) = {} of String => String,
  stdin : IO = IO::Memory.new,
  gh : Shoo::GhCli? = nil,
  credential : Shoo::Credential? = nil,
) : RunResult
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  credential_store = Shoo::CredentialStore::InMemory.new
  credential.try { |seed| credential_store.save(seed) }

  context =
    begin
      Shoo.main(
        args,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        config_path: "#{CONFIG_FIXTURE_PATH}/#{config_fixture}.yml",
        credential_store: credential_store,
        env: Shoo::Env.new(env),
        gh: gh,
      )
    rescue Shoo::ExitProgram
      nil
    end

  RunResult.new(context, stdout, stderr, credential_store)
end

def build_stdin(*lines : String) : IO
  IO::Memory.new.tap do |stdin|
    lines.each { |line| stdin.puts(line) }
    stdin.rewind
  end
end
