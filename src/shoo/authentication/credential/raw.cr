module Shoo
  module Authentication
    abstract struct Credential
      struct Raw
        include YAML::Serializable

        @[YAML::Field(converter: Shoo::Authentication::Credential::ProviderConverter)]
        getter provider : Provider?

        getter token : String?

        def initialize(@provider : Provider?, @token : String? = nil)
        end
      end
    end
  end
end
