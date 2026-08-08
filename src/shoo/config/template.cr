module Shoo
  struct Config
    module Template
      CONTENT = {{ read_file("#{__DIR__}/../../../templates/config.yml") }}
    end
  end
end
