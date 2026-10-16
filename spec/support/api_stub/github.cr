require "./github/data"
require "./github/graphql_responder"
require "./github/builder"
require "./github/resource_base"
require "./github/resource_macro"
require "./github/resources/notifications"
require "./github/resources/graphql"
require "./github/resources/user"
require "./github/resources/teams"
require "./github/resources/subscriptions"

module APIStub
  module GitHub
    BASE_URL = "https://api.github.com"

    def self.url(path : String) : String
      "#{BASE_URL}#{path}"
    end

    def self.node_id(repo : String, number : Int32) : String
      "node:#{repo}##{number}"
    end

    def self.stub(& : ->) : Nil
      with Builder.new yield
    end
  end
end
