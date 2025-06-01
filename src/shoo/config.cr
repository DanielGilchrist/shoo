require "yaml"

module Shoo
  class Config
    include YAML::Serializable

    CONFIG_DIR = "#{Path.home}/.config/shoo/config.yml"

    property notifications : NotificationConfig = NotificationConfig.new
    property github : GithubConfig = GithubConfig.new

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

    property purge : PurgeConfig = PurgeConfig.new

    def initialize
    end
  end

  class PurgeConfig
    include YAML::Serializable

    property global : PurgeRules = PurgeRules.new
    property repos : Hash(String, PurgeRules) = Hash(String, PurgeRules).new

    def initialize
    end
  end

  class PurgeRules
    include YAML::Serializable

    property keep_if : KeepRules = KeepRules.new

    def initialize
    end
  end

  class KeepRules
    include YAML::Serializable

    property author_in_teams : Array(String) = [] of String
    property authors : Array(String) = [] of String
    property? mentioned : Bool = false
    property labels : Array(String) = [] of String
    property pr_states : Array(String) = [] of String

    def initialize
    end
  end

  class GithubConfig
    include YAML::Serializable

    property token : String?

    def initialize
    end

    def github_token : String?
      token || ENV["SHOO_GITHUB_TOKEN"]?
    end
  end
end
