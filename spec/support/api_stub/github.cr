require "./github/data"
require "./github/builder"
require "./github/resource_base"
require "./github/resource_macro"
require "./github/resources/notifications"
require "./github/resources/pull_requests"
require "./github/resources/issues"
require "./github/resources/user"

module APIStub
  module GitHub
    BASE_URL = "https://api.github.com"

    def self.url(path : String) : String
      "#{BASE_URL}#{path}"
    end

    def self.stub(&)
      with Builder.new yield
    end
  end
end
