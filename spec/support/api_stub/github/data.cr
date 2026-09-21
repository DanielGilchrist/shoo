module APIStub
  module GitHub
    module Data
      extend self

      record SubjectSpec, type : String, segment : String, node : String, comments : String, error : String? = nil do
        def path(repo : String, id : String) : String
          "/repos/#{repo}/#{segment}/#{id}"
        end
      end

      alias NotificationPayload = NamedTuple(
        id: String,
        reason: String,
        subject: NamedTuple(title: String, type: String, url: String?),
        repository: NamedTuple(name: String, full_name: String, owner: NamedTuple(login: String)))

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
                       requested_teams : Array(String) = [] of String,
                       comments : Array(String) = [] of String) : SubjectSpec
        node = {
          __typename:     "PullRequest",
          state:          merged ? "MERGED" : state.upcase,
          merged:         merged,
          mergedAt:       merged_at,
          closedAt:       closed_at,
          author:         {login: author},
          reviewRequests: {nodes: requested_teams.map { |slug| {requestedReviewer: {__typename: "Team", slug: slug}} }},
        }.to_json

        comments_node = {
          __typename: "PullRequest",
          comments:   {nodes: comments.map { |body| {body: body} }},
          reviews:    {nodes: [] of Nil},
        }.to_json

        SubjectSpec.new("PullRequest", "pulls", node, comments_node)
      end

      def issue(state : String = "closed", title : String = "An issue", author : String = "octocat",
                closed_at : String? = "2020-01-01T00:00:00Z", comments : Array(String) = [] of String) : SubjectSpec
        node = {
          __typename: "Issue",
          state:      state.upcase,
          closedAt:   closed_at,
          author:     {login: author},
        }.to_json

        comments_node = {
          __typename: "Issue",
          comments:   {nodes: comments.map { |body| {body: body} }},
        }.to_json

        SubjectSpec.new("Issue", "issues", node, comments_node)
      end

      def failing_pull_request(message : String = "Could not resolve to an issue or pull request") : SubjectSpec
        SubjectSpec.new("PullRequest", "pulls", "null", "null", message)
      end

      def error(message : String = "Server Error", status : Int32 = 500) : NamedTuple(message: String, status: String)
        {message: message, status: status.to_s}
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
