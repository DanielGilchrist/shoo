module ConfigFixtures
  enum Name
    Default
    EnvToken
    NoToken
  end

  DEFAULT = <<-YAML
    github:
      token: "ghp_faketoken"

    notifications:
      purge:
        global:
          purge_if:
            merged:
              always: true
    YAML

  ENV_TOKEN = <<-YAML
    github:
      token: "GH_TOKEN"

    notifications:
      purge:
        global:
          purge_if:
            merged:
              always: true
    YAML

  NO_TOKEN = <<-YAML
    notifications:
      purge:
        global:
          purge_if:
            merged:
              always: true
    YAML

  def self.fetch(name : Name) : String
    case name
    in .default?   then DEFAULT
    in .env_token? then ENV_TOKEN
    in .no_token?  then NO_TOKEN
    end
  end
end
