module Shoo
  class Options
    class MissingParser < Exception
      def initialize
        super("parser should not be `nil`!")
      end
    end

    def initialize(
      args : Array(String),
      @dry_run = false,
      @verbose = false,
      @force = false,
      @show_help = false,
      @command : (Commands::Command.class)? = nil,
      @parser : OptionParser? = nil,
    )
      @args = args.dup
      @errors = Errors.new
    end

    getter args : Array(String)
    getter errors : Errors

    property? dry_run : Bool
    property? verbose : Bool
    property? force : Bool
    property? show_help : Bool
    property command : (Commands::Command.class)?

    setter parser : OptionParser?

    def parser : OptionParser
      @parser || raise(MissingParser.new)
    end

    def empty? : Bool
      @args.empty?
    end

    def errors? : Bool
      @errors.any?
    end

    private struct Errors
      def initialize
        @errors = Array(String).new
      end

      delegate :any?, to: @errors

      def add(error : String)
        @errors << error
      end

      def to_s(io)
        io << @errors.join("\n")
      end
    end
  end
end
