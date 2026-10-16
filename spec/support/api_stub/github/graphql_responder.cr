module APIStub
  module GitHub
    # Answers the queries shoo builds at runtime from what the builder registered,
    # so specs describe notifications, identities and teams once and never spell
    # out query text.
    struct GraphQLResponder
      alias Subjects = Hash(Tuple(String, Int32), Data::SubjectSpec)
      alias Teams = Hash(Tuple(String, String), Array(String))
      alias Unsubscribes = Hash(String, String?)

      class UnsubscribeScope
        property? missing : Bool = false
      end

      record Failure, status : Int32, body : String
      record Identity, login : String, scopes : String

      REPOSITORY  = /(\w+): repository\(owner: "([^"]+)", name: "([^"]+)"\)/
      SUBJECT     = /(\w+): issueOrPullRequest\(number: (\d+)\)/
      TEAM        = /organization\(login: "([^"]+)"\) \{ team\(slug: "([^"]+)"\)/
      UNSUBSCRIBE = /(\w+): updateSubscription\(input: \{subscribableId: "([^"]+)", state: UNSUBSCRIBED\}\)/
      COMMENTS    = "comments(last:"
      VIEWER      = "query { viewer {"
      MUTATION    = "mutation {"

      def initialize(@subjects : Subjects, @teams : Teams, @unsubscribes : Unsubscribes, @unsubscribe_scope : UnsubscribeScope, @identity : Identity?, @failure : Failure?) : Nil
      end

      def respond(request : HTTP::Request) : HTTP::Client::Response
        if failure = @failure
          return HTTP::Client::Response.new(failure.status, failure.body)
        end

        query = JSON.parse(request.body.try(&.gets_to_end) || "{}")["query"].as_s

        if query.starts_with?(VIEWER)
          identity = @identity || raise "APIStub: no identity registered"
          headers = HTTP::Headers{"X-OAuth-Scopes" => identity.scopes}
          return HTTP::Client::Response.new(200, {data: {viewer: {login: identity.login}}}.to_json, headers)
        end

        if query.starts_with?(MUTATION)
          return HTTP::Client::Response.new(200, unsubscribe_envelope(query))
        end

        if match = TEAM.match(query)
          return HTTP::Client::Response.new(200, team_envelope(match[1], match[2]))
        end

        HTTP::Client::Response.new(200, subjects_envelope(query))
      end

      private def team_envelope(organisation : String, slug : String) : String
        members = @teams[{organisation, slug}]?
        team = members ? {members: {pageInfo: {hasNextPage: false, endCursor: nil}, nodes: members.map { |login| {login: login} }}} : nil
        {data: {organization: {team: team}}}.to_json
      end

      private def unsubscribe_envelope(query : String) : String
        if @unsubscribe_scope.missing?
          return {errors: [{type: "INSUFFICIENT_SCOPES", message: "The 'updateSubscription' field requires one of the following scopes: ['notifications']"}]}.to_json
        end

        errors = [] of NamedTuple(message: String, path: Array(String))

        data = query.scan(UNSUBSCRIBE).to_h do |match|
          alias_name, node_id = match[1], match[2]
          raise "APIStub: no unsubscribe registered for #{node_id}" unless @unsubscribes.has_key?(node_id)

          if error = @unsubscribes[node_id]
            errors << {message: error, path: [alias_name]}
            {alias_name, nil}
          else
            {alias_name, {clientMutationId: nil}}
          end
        end

        {data: data, errors: errors}.to_json
      end

      private def with_node_id(node : String, node_id : String) : String
        case parsed = JSON.parse(node).as_h?
        in Hash then parsed.merge({"id" => JSON::Any.new(node_id)}).to_json
        in Nil  then node
        end
      end

      private def subjects_envelope(query : String) : String
        wants_comments = query.includes?(COMMENTS)
        errors = [] of NamedTuple(message: String, path: Array(String))
        repository_alias = ""
        repository = ""

        data = JSON.build do |json|
          json.object do
            query.scan(/#{REPOSITORY}|#{SUBJECT}/).each do |match|
              if match[1]?
                json.end_object unless repository_alias.empty?
                repository_alias = match[1]
                repository = "#{match[2]}/#{match[3]}"
                json.field(repository_alias) { json.start_object }
              else
                subject_alias = match[4]
                spec = @subjects[{repository, match[5].to_i}]? || raise "APIStub: no subject registered for #{repository}##{match[5]}"

                if error = spec.error
                  errors << {message: error, path: [repository_alias, subject_alias]}
                end

                node_id = GitHub.node_id(repository, match[5].to_i)
                json.field(subject_alias) { json.raw(wants_comments ? spec.comments : with_node_id(spec.node, node_id)) }
              end
            end
            json.end_object unless repository_alias.empty?
          end
        end

        {data: JSON.parse(data), errors: errors}.to_json
      end
    end
  end
end
