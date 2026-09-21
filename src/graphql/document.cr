module GraphQL
  # Composes a query document at runtime, for the parts a compile-time selection
  # cannot express: aliases and arguments that depend on data.
  #
  #   GraphQL::Document.query do
  #     field("repository", as: "r0", owner: "org", name: "repo") do
  #       field("issueOrPullRequest", IssueOrPullRequestFragment, as: "s0", number: 1)
  #     end
  #   end
  struct Document
    alias Scalar = String | Int::Primitive | Float::Primitive | Bool | Nil | EnumValue
    alias Argument = Scalar | Array(Scalar)

    def self.query(& : ->) : String
      String.build do |io|
        io << "query {"
        with Builder.new(io) yield
        io << " }"
      end
    end

    def self.encode(io : IO, value : Array(Scalar)) : Nil
      io << '['
      value.each_with_index do |element, index|
        io << ", " unless index.zero?
        encode(io, element)
      end
      io << ']'
    end

    def self.encode(io : IO, value : Scalar) : Nil
      case value
      in EnumValue                                           then io << value.name
      in String, Int::Primitive, Float::Primitive, Bool, Nil then value.to_json(io)
      end
    end
  end
end
