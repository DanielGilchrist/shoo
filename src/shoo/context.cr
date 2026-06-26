module Shoo
  class Context
    getter config : Config
    getter stdout : IO
    getter stderr : IO
    getter stdin : IO

    def initialize(@config : Config, @client : GitHub::Client?, @stdout : IO, @stderr : IO, @stdin : IO)
    end

    def client : GitHub::Client
      @client || abort!("GitHub token not provided!")
    end

    def abort!(message : String) : NoReturn
      @stderr.puts message
      raise ExitProgram.new(1)
    end
  end
end
