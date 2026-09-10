module APIStub
  module GitHub
    module Data
      extend self

      struct SubjectSpec
        getter type : String
        getter segment : String
        getter body : String
        getter status : Int32

        def initialize(@type : String, @segment : String, @body : String, @status : Int32 = 200) : Nil
        end

        def path(repo : String, id : String) : String
          "/repos/#{repo}/#{segment}/#{id}"
        end
      end

      alias NotificationPayload = NamedTuple(
        id: String,
        reason: String,
        subject: NamedTuple(title: String, type: String, url: String?),
        repository: NamedTuple(full_name: String))

      record NotificationSpec,
        reason : String,
        title : String,
        repo : String,
        id : String?,
        subject : SubjectSpec?

      def notification(reason : String = "subscribed", title : String = "A notification",
                       repo : String = "org/repo", id : String? = nil, subject : SubjectSpec? = nil) : NotificationSpec
        NotificationSpec.new(reason, title, repo, id, subject)
      end

      def pull_request(merged : Bool = true, title : String = "A pull request", author : String = "octocat",
                       state : String = "closed", merged_at : String? = "2020-01-01T00:00:00Z",
                       closed_at : String? = "2020-01-01T00:00:00Z",
                       requested_teams : Array(String) = [] of String) : SubjectSpec
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

      def issue(state : String = "closed", title : String = "An issue", author : String = "octocat",
                closed_at : String? = "2020-01-01T00:00:00Z") : SubjectSpec
        body = {
          user:         {login: author},
          title:        title,
          state:        state,
          comments_url: "https://api.github.com/repos/org/repo/issues/1/comments",
          closed_at:    closed_at,
        }.to_json
        SubjectSpec.new("Issue", "issues", body)
      end

      def failing_pull_request(status : Int32 = 500, message : String = "Server Error") : SubjectSpec
        SubjectSpec.new("PullRequest", "pulls", error(message, status).to_json, status)
      end

      def error(message : String = "Server Error", status : Int32 = 500) : NamedTuple(message: String, documentation_url: String, status: String)
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
