module Shoo
  module GitHub
    struct Client
      struct Subjects
        struct Batch(T)
          CHUNK_SIZE = 100
          FIELD      = "issueOrPullRequest"

          def initialize(@graphql : ::GraphQL::Client) : Nil
          end

          def fetch(refs : Array(SubjectRef)) : Hash(SubjectRef, T | Unresolved) | ::GraphQL::Failure
            chunks = refs.uniq.each_slice(CHUNK_SIZE).to_a
            results = Future.all(chunks) { |chunk| execute_chunk(chunk) }

            results.each_with_object(Hash(SubjectRef, T | Unresolved).new) do |result, outcomes|
              case result
              in Hash(SubjectRef, T | Unresolved) then outcomes.merge!(result)
              in ::GraphQL::Failure               then return result
              end
            end
          end

          private def execute_chunk(refs : Array(SubjectRef)) : Hash(SubjectRef, T | Unresolved) | ::GraphQL::Failure
            prepared = prepare(refs)

            case envelope = @graphql.execute(prepared.text, Hash(String, Hash(String, T?)?))
            in ::GraphQL::Envelope(Hash(String, Hash(String, T?)?)) then resolve(prepared, envelope)
            in ::GraphQL::Failure                                   then envelope
            end
          end

          private def prepare(refs : Array(SubjectRef)) : Prepared
            aliases = Hash(SubjectRef, Tuple(String, String)).new

            text = ::GraphQL::Document.query do
              refs.group_by(&.repository).each_with_index do |(repository, repository_refs), repository_index|
                repository_alias = "r#{repository_index}"

                field("repository", as: repository_alias, owner: repository[0], name: repository[1]) do
                  repository_refs.each_with_index do |ref, subject_index|
                    subject_alias = "s#{subject_index}"
                    aliases[ref] = {repository_alias, subject_alias}
                    field(FIELD, T, as: subject_alias, number: ref.number)
                  end
                end
              end
            end

            Prepared.new(text, aliases)
          end

          private def resolve(prepared : Prepared, envelope : ::GraphQL::Envelope(Hash(String, Hash(String, T?)?))) : Hash(SubjectRef, T | Unresolved)
            prepared.aliases.each_with_object(Hash(SubjectRef, T | Unresolved).new) do |(ref, (repository_alias, subject_alias)), outcomes|
              outcomes[ref] =
                case repository = envelope.data[repository_alias]?
                in Nil
                  Unresolved.new(envelope.error_at?(repository_alias).try(&.message) || "repository #{ref.owner}/#{ref.name} was not returned")
                in Hash(String, T?)
                  case node = repository[subject_alias]?
                  in Nil then Unresolved.new(envelope.error_at?(repository_alias, subject_alias).try(&.message) || "##{ref.number} was not returned")
                  in T   then node
                  end
                end
            end
          end
        end
      end
    end
  end
end
