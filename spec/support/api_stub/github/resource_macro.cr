module APIStub
  module GitHub
    macro resource(name, &block)
      class {{name.id.camelcase}}Resource < ResourceBase
        {{ block.body }}
      end

      class Builder
        def {{name.id}} : {{name.id.camelcase}}Resource
          {{name.id.camelcase}}Resource.new(self)
        end
      end
    end
  end
end
