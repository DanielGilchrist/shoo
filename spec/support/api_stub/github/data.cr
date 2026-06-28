module APIStub
  module GitHub
    module Data
      extend self

      struct SubjectSpec
        getter type : String
        getter segment : String
        getter body : String
        getter status : Int32

        def initialize(@type, @segment, @body, @status = 200)
        end

        def path(repo : String, id : String) : String
          "/repos/#{repo}/#{segment}/#{id}"
        end
      end

      record NotificationSpec,
        reason : String,
        title : String,
        repo : String,
        id : String?,
        subject : SubjectSpec?

      def notification(reason = "subscribed", title = "A notification",
                       repo = "org/repo", id : String? = nil, subject : SubjectSpec? = nil)
        NotificationSpec.new(reason, title, repo, id, subject)
      end

      def pull_request(merged = true, title = "A pull request", author = "octocat",
                       state = "closed", merged_at : String? = "2020-01-01T00:00:00Z",
                       closed_at : String? = "2020-01-01T00:00:00Z",
                       requested_teams : Array(String) = [] of String)
        body = {
          user:                {login: author},
          title:               title,
          state:               state,
          requested_teams:     requested_teams.map { |slug| {slug: slug} },
          review_comments_url: "https://api.github.com/repos/org/repo/pulls/1/comments",
          comments_url:        "https://api.github.com/repos/org/repo/issues/1/comments",
          merged:              merged,
          merged_at:           merged_at,
          closed_at:           closed_at,
        }.to_json
        SubjectSpec.new("PullRequest", "pulls", body)
      end

      def issue(state = "closed", title = "An issue", author = "octocat",
                closed_at : String? = "2020-01-01T00:00:00Z")
        body = {
          user:         {login: author},
          title:        title,
          state:        state,
          comments_url: "https://api.github.com/repos/org/repo/issues/1/comments",
          closed_at:    closed_at,
        }.to_json
        SubjectSpec.new("Issue", "issues", body)
      end

      def failing_pull_request(status = 500, message = "Server Error")
        SubjectSpec.new("PullRequest", "pulls", error(message, status).to_json, status)
      end

      def error(message = "Server Error", status = 500)
        {message: message, documentation_url: "https://docs.github.com", status: status.to_s}
      end

      def resolve_ids(specs : Array(NotificationSpec)) : Array(Tuple(NotificationSpec, String))
        resolved = specs.map_with_index { |spec, index| {spec, spec.id || (index + 1).to_s} }

        ids = resolved.map { |(_, id)| id }
        dupes = ids.select { |id| ids.count(id) > 1 }.uniq!
        raise "APIStub: duplicate notification id(s) #{dupes}" unless dupes.empty?

        resolved
      end
    end
  end
end
