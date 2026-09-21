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
    alias Argument = Scalar

    def self.query(& : ->) : String
      String.build do |io|
        io << "query {"
        with Builder.new(io) yield
        io << " }"
      end
    end

    def self.encode(io : IO, value : Scalar) : Nil
      case value
      in EnumValue                                           then io << value.name
      in String, Int::Primitive, Float::Primitive, Bool, Nil then value.to_json(io)
      end
    end
  end
end
