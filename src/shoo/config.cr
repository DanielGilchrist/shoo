require "yaml"

module Shoo
  class Config
    include YAML::Serializable

    CONFIG_DIR = "#{Path.home}/.config/shoo/config.yml"

    getter notifications : NotificationConfig = NotificationConfig.new
    getter github : GithubConfig = GithubConfig.new

    def self.load(path : String = CONFIG_DIR) : Config
      if File.exists?(path)
        Config.from_yaml(File.read(path))
      else
        Config.new
      end
    end

    def initialize
    end
  end

  class NotificationConfig
    include YAML::Serializable

    getter purge : PurgeConfig = PurgeConfig.new

    def initialize
    end
  end

  class PurgeConfig
    include YAML::Serializable

    getter global : PurgeRules = PurgeRules.new
    getter repos : Hash(String, PurgeRules) = Hash(String, PurgeRules).new

    def initialize
    end
  end

  class PurgeRules
    include YAML::Serializable

    getter keep_if : KeepRules = KeepRules.new

    def initialize
    end
  end

  class KeepRules
    include YAML::Serializable

    getter author_in_teams : Array(String) = [] of String
    getter authors : Array(String) = [] of String
    getter? mentioned : Bool = false
    getter labels : Array(String) = [] of String
    getter pr_states : Array(String) = [] of String

    def initialize
    end
  end

  class GithubConfig
    include YAML::Serializable

    getter token : String?

    def initialize
    end

    def github_token : String?
      token || ENV["SHOO_GITHUB_TOKEN"]?
    end
  end
end
