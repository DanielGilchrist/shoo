module Shoo
  module Authentication
    abstract struct Credential
      module ProviderConverter
        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Provider?
          scalar = node.as?(YAML::Nodes::Scalar)
          scalar ? Provider.parse?(scalar.value) : nil
        end

        def self.to_yaml(value : Provider, yaml : YAML::Nodes::Builder) : Nil
          yaml.scalar(value.to_s.downcase)
        end
      end
    end
  end
end
