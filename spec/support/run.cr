CONFIG_FIXTURE_PATH = "spec/fixtures/config"

struct RunResult
  getter context : Shoo::Context?
  getter stdout : IO::Memory
  getter stderr : IO::Memory

  def initialize(@context : Shoo::Context?, @stdout : IO::Memory, @stderr : IO::Memory)
  end
end

def run(
  args : Array(String),
  config_fixture : String = "default",
  env : Hash(String, String) = {} of String => String,
  stdin : IO = IO::Memory.new,
  gh : Shoo::GhCli? = nil,
  credentials_path : String = File.tempname("shoo-credentials"),
) : RunResult
  stdout = IO::Memory.new
  stderr = IO::Memory.new

  context =
    begin
      Shoo.main(
        args,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        config_path: "#{CONFIG_FIXTURE_PATH}/#{config_fixture}.yml",
        credentials_path: credentials_path,
        env: Shoo::Env.new(env),
        gh: gh,
      )
    rescue Shoo::ExitProgram
      nil
    end

  RunResult.new(context, stdout, stderr)
end

def build_stdin(*lines : String) : IO
  IO::Memory.new.tap do |stdin|
    lines.each { |line| stdin.puts(line) }
    stdin.rewind
  end
end
