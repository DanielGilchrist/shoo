module GraphQL
  # Defines a whole operation: the data struct that decodes its response and the
  # `DOCUMENT` text that `Client#execute` sends.
  #
  #   GraphQL.query ViewerQuery do
  #     viewer do
  #       login String
  #     end
  #   end
  #
  #   client.execute(ViewerQuery)  # => Envelope(ViewerQuery) | Failure
  macro query(name, &block)
    ::GraphQL::Definition.object({{ name }}) {{ block }}

    struct {{ name }}
      include ::GraphQL::Query

      DOCUMENT = "query { " + SELECTION + " }"
    end
  end

  # Defines a selection set on a type, for `Document::Builder#field` to splice
  # into an operation built at runtime.
  #
  #   GraphQL.fragment IssueFragment do
  #     title String
  #     author? { login String }
  #   end
  #
  # A block containing only `on Type do ... end` entries defines a discriminated
  # fragment: the struct exposes a `variant` union of one struct per `on` plus
  # `Unknown` for typenames the fragment did not name.
  macro fragment(name, &block)
    ::GraphQL::Definition.object({{ name }}) {{ block }}

    struct {{ name }}
      include ::GraphQL::Fragment
    end
  end

  # :nodoc:
  module Definition
    # :nodoc:
    macro object(name, &block)
      {% nodes = block.body.is_a?(Expressions) ? block.body.expressions : [block.body] %}
      {% discriminated = nodes.any? { |node| node.is_a?(Call) && node.name == "on" } %}
      struct {{ name }}
        {% if discriminated %}
          ::GraphQL::Definition.variants {{ block }}
        {% else %}
          include ::JSON::Serializable
          ::GraphQL::Definition.fields {{ block }}
        {% end %}
      end
    end

    # :nodoc:
    macro variants(&block)
      {% names = [] of Nil %}
      {% for node in (block.body.is_a?(Expressions) ? block.body.expressions : [block.body]) %}
        {% if node.is_a?(Call) && node.name == "on" && node.args.size == 1 && node.block %}
          {% names << node.args[0] %}
          ::GraphQL::Definition.object({{ node.args[0] }}) {{ node.block }}
        {% else %}
          {% node.raise "GraphQL::Definition: a discriminated selection may only contain `on Type do ... end` entries, got `#{node}`" %}
        {% end %}
      {% end %}

      record Unknown, typename : String

      alias Variant = {{ names.join(" | ").id }} | Unknown

      getter variant : Variant

      def initialize(@variant : Variant) : Nil
      end

      def self.new(pull : ::JSON::PullParser) : self
        typename = nil
        location = pull.location

        json = ::String.build do |io|
          ::JSON.build(io) do |builder|
            builder.start_object
            pull.read_object do |key|
              if key == "__typename"
                typename = pull.read_string
                builder.field(key, typename)
              else
                builder.field(key) { pull.read_raw(builder) }
              end
            end
            builder.end_object
          end
        end

        unless typename
          raise ::JSON::SerializableError.new("Missing __typename in discriminated selection", to_s, nil, *location, nil)
        end

        new(
          case typename
          {% for name in names %}
          when {{ name.stringify }} then {{ name }}.from_json(json)
          {% end %}
          else Unknown.new(typename)
          end
        )
      end

      SELECTION = "__typename"{% for name in names %} + " ... on {{ name }} { " + {{ name }}::SELECTION + " }"{% end %}
    end

    # :nodoc:
    macro fields(&block)
      {% parts = [] of Nil %}
      {% for node in (block.body.is_a?(Expressions) ? block.body.expressions : [block.body]) %}
        {% node.raise "GraphQL::Definition: expected a field declaration, got `#{node}`" unless node.is_a?(Call) %}
        {% arguments = node.named_args ? "(#{node.named_args.map { |arg| "#{arg.name}: #{arg.value.is_a?(SymbolLiteral) ? arg.value.id : arg.value}" }.join(", ").id})" : "" %}

        {% if node.block %}
          {% list = node.args.size == 1 && "#{node.args[0]}" == "Array" %}
          {% node.raise "GraphQL::Definition: an object field takes no positional arguments other than `Array`, got `#{node}`" unless node.args.size == (list ? 1 : 0) %}
          {% nullable = node.name.ends_with?("?") %}
          {% field = node.name.gsub(/\?$/, "") %}
          {% type = field.camelcase.id %}
          {% parts << "\"#{field}#{arguments.id} { \" + #{type}::SELECTION + \" }\"" %}

          ::GraphQL::Definition.object({{ type }}) {{ node.block }}

          @[::JSON::Field(key: {{ field.stringify }})]
          getter {{ field.underscore.id }} : {{ list ? "Array(#{type})".id : type }}{{ nullable ? "?".id : "".id }}
        {% else %}
          {% node.raise "GraphQL::Definition: a scalar field needs exactly one type, e.g. `#{node.name} String`" unless node.args.size == 1 %}
          {% parts << "\"#{node.name}#{arguments.id}\"" %}

          @[::JSON::Field(key: {{ node.name.stringify }})]
          getter {{ node.name.underscore.id }} : {{ node.args[0] }}
        {% end %}
      {% end %}

      SELECTION = {{ parts.join(" + \" \" + ").id }}
    end
  end
end
