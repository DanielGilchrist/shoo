module Shoo
  struct Prompt
    def initialize(@stdin : IO, @stdout : IO)
    end

    def choose(message : String, options : Array(T), & : T -> String) : T? forall T
      @stdout.puts message
      options.each_with_index do |option, index|
        @stdout.puts "    #{index + 1}) #{yield option}"
      end
      @stdout.print "  Choose [1]: "

      choice = @stdin.gets.try(&.strip)
      index = choice.nil? || choice.empty? ? 0 : choice.to_i?.try(&.pred)
      return unless index
      return if index < 0

      options[index]?
    end

    def confirm(question : String) : Bool
      @stdout.print "  #{question} [Y/n]: "
      answer = @stdin.gets.try(&.strip.downcase)
      answer.nil? || answer.empty? || answer.in?("y", "yes")
    end

    def ask(question : String) : String?
      @stdout.print question
      @stdin.gets.try(&.strip)
    end
  end
end
