module Shoo
  module GitHub
    struct Client
      struct Teams
        # Pages through a team's members. Built at runtime because the login, slug
        # and cursor are arguments.
        struct MembersPager
          PAGE_SIZE = 100

          alias Data = Hash(String, Hash(String, Hash(String, Queries::TeamMembersPageFragment?)?)?)

          def initialize(@graphql : ::GraphQL::Client) : Nil
          end

          def members(organisation_name : String, team_slug : String) : Array(String) | Unresolved | ::GraphQL::Failure
            logins = Array(String).new
            cursor = nil.as(String?)

            loop do
              case page = fetch_page(organisation_name, team_slug, cursor)
              in Unresolved, ::GraphQL::Failure
                return page
              in Queries::TeamMembersPageFragment
                logins.concat(page.nodes.map(&.login))
                return logins unless page.page_info.has_next_page

                cursor = page.page_info.end_cursor
              end
            end
          end

          private def fetch_page(organisation_name : String, team_slug : String, cursor : String?) : Queries::TeamMembersPageFragment | Unresolved | ::GraphQL::Failure
            document = ::GraphQL::Document.query do
              field("organization", login: organisation_name) do
                field("team", slug: team_slug) do
                  field("members", Queries::TeamMembersPageFragment, first: PAGE_SIZE, after: cursor)
                end
              end
            end

            case envelope = @graphql.execute(document, Data)
            in ::GraphQL::Failure        then envelope
            in ::GraphQL::Envelope(Data) then envelope.data.dig?("organization", "team", "members") || Unresolved.new("team #{organisation_name}/#{team_slug} was not found")
            end
          end
        end
      end
    end
  end
end
