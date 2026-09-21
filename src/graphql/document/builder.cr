module GraphQL
  module Document
    struct Builder
      def initialize(@io : IO) : Nil
      end

      def field(field_name : String, *, as alias_name : String? = nil, **arguments : Argument, & : ->) : Nil
        open(field_name, alias_name, arguments)
        @io << " {"
        with self yield
        @io << " }"
      end

      def field(field_name : String, fragment : T.class, *, as alias_name : String? = nil, **arguments : Argument) : Nil forall T
        {% T.raise "#{T} is not a GraphQL.fragment" unless T < ::GraphQL::Fragment %}
        open(field_name, alias_name, arguments)
        @io << " { " << T::SELECTION << " }"
      end

      private def open(field_name : String, alias_name : String?, arguments : NamedTuple) : Nil
        @io << ' '
        @io << alias_name << ": " if alias_name
        @io << field_name
        return if arguments.empty?

        @io << '('
        arguments.each_with_index do |key, value, index|
          @io << ", " unless index.zero?
          @io << key << ": "
          Document.encode(@io, value)
        end
        @io << ')'
      end
    end
  end
end
