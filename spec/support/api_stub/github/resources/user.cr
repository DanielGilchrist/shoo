module APIStub
  module GitHub
    resource :user do
      def identity(login = "octocat", scopes = "notifications", status = 200)
        body = status == 200 ? {login: login}.to_json : Data.error(status: status).to_json
        stub(:get, "/user", status: status, body: body, headers: {"X-OAuth-Scopes" => scopes})
      end
    end
  end
end
