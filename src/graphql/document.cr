module GraphQL
  # Composes a query document at runtime, for the parts a compile-time selection
  # cannot express: aliases and arguments that depend on data.
  #
  #   GraphQL::Document.query do
  #     field("repository", as: "r0", owner: "org", name: "repo") do
  #       field("issueOrPullRequest", IssueOrPullRequestFragment, as: "s0", number: 1)
  #     end
  #   end
  module Document
    alias Scalar = String | Int::Primitive | Float::Primitive | Bool | EnumValue?
    alias Input = Hash(String, Scalar)
    alias Argument = Scalar | Input

    def self.query(& : ->) : String
      String.build do |io|
        io << "query {"
        with Builder.new(io) yield
        io << " }"
      end
    end

    def self.mutation(& : ->) : String
      String.build do |io|
        io << "mutation {"
        with Builder.new(io) yield
        io << " }"
      end
    end

    def self.encode(io : IO, value : Argument) : Nil
      case value
      in Input
        io << '{'
        value.each_with_index do |(key, field_value), index|
          io << ", " unless index.zero?
          io << key << ": "
          encode(io, field_value)
        end
        io << '}'
      in EnumValue                                           then io << value.name
      in String, Int::Primitive, Float::Primitive, Bool, Nil then value.to_json(io)
      end
    end
  end
end
