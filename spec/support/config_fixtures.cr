module ConfigFixtures
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

  def self.fetch(name : String) : String
    case name
    when "default"   then DEFAULT
    when "env_token" then ENV_TOKEN
    when "no_token"  then NO_TOKEN
    else                  raise "unknown config fixture: #{name}"
    end
  end
end
